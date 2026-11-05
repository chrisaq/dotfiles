"""Interactive, single-unit review. Viewing and selection never restart a service."""

from __future__ import annotations
import asyncio
from textual import on, work
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, DataTable, Label, Static, TextArea
from rich.text import Text
from .engine import check_one, log_event
from .config import load
from .providers.base import Context
from .providers.systemd import restart_unit, unit_logs
from .util import Problem


class UnitReview(ModalScreen):
    CSS = """
    UnitReview {align:center middle; background:$background 80%;}
    #ur-box {width:96%; height:94%; background:$surface; border:round $primary; padding:0 1;}
    #ur-title {height:2; color:$primary; text-style:bold;}
    #ur-units {height:8; border:round $primary-muted;}
    #ur-hint {height:auto; max-height:4; margin:1 0; color:$text-muted;}
    #ur-logs {height:1fr; border:round $secondary;}
    #ur-status {height:auto; max-height:3; margin:1 0;}
    #ur-buttons {height:3;}
    #ur-buttons Button {width:1fr; min-width:12; margin-right:1;}
    """
    BINDINGS = [
        Binding("escape", "close", "Back", priority=True),
        Binding("ctrl+r", "refresh", "Refresh", priority=True),
    ]

    def __init__(self, id, config):
        super().__init__()
        self.id_check = id
        self.config = config
        self.units = {}
        self.selected = None
        self.busy = False
        self.seq = 0
        self.repair_id = None
        self.outcome = ""

    def compose(self):
        with Vertical(id="ur-box"):
            yield Label("Failed units · review one service at a time", id="ur-title")
            yield DataTable(id="ur-units", cursor_type="row")
            yield Static(
                "Select a unit to inspect its logs. No action runs on selection.",
                id="ur-hint",
                markup=False,
            )
            yield TextArea("", read_only=True, soft_wrap=True, id="ur-logs")
            yield Static("Loading failed units…", id="ur-status", markup=False)
            with Horizontal(id="ur-buttons"):
                yield Button("Refresh", id="ur-refresh")
                yield Button(
                    "Restart selected",
                    id="ur-restart",
                    variant="warning",
                    disabled=True,
                )
                yield Button("Unlock & sync", id="ur-repair", disabled=True)
                yield Button("Back", id="ur-close")

    def on_mount(self):
        self.query_one("#ur-units", DataTable).add_columns("Scope", "Failed unit")
        self.query_one("#ur-logs").border_title = "Journal · last 100 entries"
        self.action_refresh()

    def status(self, text):
        self.query_one("#ur-status", Static).update(Text(text))

    def controls(self):
        self.query_one("#ur-restart", Button).disabled = (
            self.busy or self.selected is None
        )
        self.query_one("#ur-repair", Button).disabled = self.busy or not self.repair_id
        self.query_one("#ur-refresh", Button).disabled = self.busy

    @work(exclusive=True, group="unit-refresh")
    async def action_refresh(self):
        if self.busy:
            return
        self.seq += 1
        try:
            result = await asyncio.to_thread(
                check_one, self.id_check, self.config, True
            )
            self.units = {
                r["scope"] + ":" + r["unit"]: r for r in result.metrics.get("units", [])
            }
            table = self.query_one("#ur-units", DataTable)
            old = self.selected
            table.clear()
            self.selected = None
            self.repair_id = None
            for key, r in self.units.items():
                table.add_row(r["scope"], r["unit"], key=key)
            if self.units:
                key = next(
                    (k for k, v in self.units.items() if v == old),
                    next(iter(self.units)),
                )
                table.move_cursor(row=list(self.units).index(key))
                self.choose(self.units[key])
            else:
                self.query_one("#ur-logs", TextArea).load_text("")
                self.query_one("#ur-hint", Static).update(
                    "No failed units remain."
                    if result.state == "ok"
                    else result.summary
                )
            self.status((self.outcome + "\n" if self.outcome else "") + result.summary)
            self.controls()
        except Exception as error:
            self.status(
                str(error)
                if isinstance(error, Problem)
                else "Could not refresh failed units."
            )
            self.controls()

    @on(DataTable.RowHighlighted, "#ur-units")
    def highlighted(self, event):
        event.stop()
        if self.busy:
            return
        row = self.units.get(str(event.row_key.value))
        if row:
            self.choose(row)

    def choose(self, row):
        self.selected = row
        self.repair_id = None
        component = (
            {"cq-mail.service": "mail", "cq-contacts.service": "contacts"}.get(
                row["unit"]
            )
            if row["scope"] == "user"
            else None
        )
        if component:
            self.repair_id = next(
                (
                    id
                    for id, c in load().checks.items()
                    if c.enabled
                    and c.provider == "mail"
                    and c.options.get("component", id) == component
                ),
                None,
            )
        hint = row["scope"] + ": " + row["unit"]
        if component:
            hint += "\nThese background jobs never prompt for a GPG unlock. If logs say unlock required, use Unlock & sync; Restart selected keeps the quiet background policy."
        elif row["scope"] == "system":
            hint += "\nRestart requires sudo authentication in your terminal."
        self.query_one("#ur-hint", Static).update(Text(hint))
        self.controls()
        self.read_logs(row)

    @work(exclusive=True, group="unit-logs")
    async def read_logs(self, row):
        self.seq += 1
        seq = self.seq
        try:
            text = await asyncio.to_thread(
                unit_logs, Context(self.id_check, self.config, checking=False), row
            )
            if seq == self.seq and self.is_mounted:
                self.query_one("#ur-logs", TextArea).load_text(text)
        except Exception as error:
            if seq == self.seq:
                self.status(
                    str(error)
                    if isinstance(error, Problem)
                    else "Could not read unit logs."
                )

    @on(Button.Pressed)
    def clicked(self, event):
        if not (event.button.id or "").startswith("ur-"):
            return
        event.stop()
        key = event.button.id.removeprefix("ur-")
        if key == "restart":
            self.restart_selected()
        elif key == "repair":
            self.repair_selected()
        else:
            getattr(self, "action_" + key)()

    @work(group="unit-mutation")
    async def restart_selected(self):
        if self.busy or not self.selected:
            return
        from .dashboard import ConfirmAction

        row = dict(self.selected)
        self.busy = True
        self.controls()
        try:
            if not await self.app.push_screen_wait(
                ConfirmAction(
                    "Restart selected unit?",
                    row["scope"]
                    + ": "
                    + row["unit"]
                    + "\n\nOnly this unit will be restarted, after verifying it is still failed.",
                )
            ):
                return
            if row["scope"] == "system":
                code = self.app.launch(
                    [
                        "restart-unit",
                        self.id_check,
                        row["unit"],
                        "--scope",
                        "system",
                        "--yes",
                    ]
                )
                self.outcome = (
                    "Restart command completed; refreshed unit state below."
                    if code == 0
                    else "Restart command failed; inspect its terminal output and journal."
                )
            else:
                message = await asyncio.to_thread(
                    restart_unit,
                    Context(self.id_check, self.config, checking=False),
                    row,
                )
                log_event(
                    {"id": self.id_check, "state": "completed", "message": message}
                )
                self.outcome = message
                self.status(message)
        except Exception as error:
            message = (
                str(error)
                if isinstance(error, Problem)
                else "Restart failed; inspect the journal."
            )
            log_event({"id": self.id_check, "state": "blocked", "message": message})
            self.outcome = message
            self.status(message)
        finally:
            self.busy = False
            self.controls()
            # Preserve the explicit outcome while updating the table and journal.
            self.action_refresh()

    @work(group="unit-mutation")
    async def repair_selected(self):
        if self.busy or not self.repair_id:
            return
        from .dashboard import ConfirmAction

        target = self.repair_id
        self.busy = True
        self.controls()
        try:
            if await self.app.push_screen_wait(
                ConfirmAction(
                    "Unlock credentials and sync?",
                    target
                    + "\n\nRun a foreground sync, allowing your normal GPG unlock prompt. After success, its matching failed-unit flag is cleared.",
                )
            ):
                code = self.app.launch(["fix", target, "--yes"])
                self.outcome = (
                    "Foreground sync completed; refreshed unit state below."
                    if code == 0
                    else "Foreground sync did not complete; inspect its output or unlock credentials."
                )
        finally:
            self.busy = False
            self.controls()
            self.action_refresh()

    def action_close(self):
        if self.busy:
            self.status("Wait for the current action to finish.")
            return
        self.seq += 1
        self.dismiss()
