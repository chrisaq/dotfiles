"""On-demand setup view. It never installs anything while inspecting or selecting."""

import asyncio, hashlib
from textual import on, work
from textual.binding import Binding
from textual.containers import Horizontal, VerticalScroll, HorizontalScroll
from textual.screen import ModalScreen
from textual.widgets import Button, DataTable, Static
from rich.text import Text
from ..config import load, toggle_setup
from ..util import Problem, read_json, state_dir
from .core import inspect_all, plan

COLORS = {
    "ready": "green",
    "required": "yellow",
    "blocked": "red",
    "unavailable": "grey70",
    "disabled": "grey50",
    "unsupported": "grey50",
}


def plan_token(value):
    return hashlib.sha256(value.model_dump_json().encode()).hexdigest()


class SetupScreen(ModalScreen):
    DEFAULT_CSS = """SetupScreen {background:$background;} #su-title {height:auto; min-height:3; padding:1; color:$primary; background:$surface;} #su-body {height:1fr;} #su-items {width:35%; border:round $primary-muted;} #su-pane {width:65%; padding:0 1; border:round $secondary-muted;} #su-detail {height:auto;} #su-buttons {height:3;} #su-buttons Button {min-width:14; margin-right:1;} #su-status {height:2; padding:0 1;} SetupScreen.narrow #su-body {layout:vertical;} SetupScreen.narrow #su-items {width:100%; height:10;} SetupScreen.narrow #su-pane {width:100%; height:1fr;}"""
    BINDINGS = [
        Binding("escape", "close", "Health", priority=True),
        Binding("ctrl+r", "refresh", "Inspect", priority=True),
        Binding("e", "toggle", "Enable/disable", priority=True),
    ]

    def __init__(self, selected=None):
        super().__init__()
        self.selected = selected
        self.rows = {}
        self.current_plan = None
        self.busy = False
        self.seq = 0

    def compose(self):
        yield Static(
            "Machine setup · explicit, reviewed installation and repair · hidden from Waybar by default",
            id="su-title",
        )
        with Horizontal(id="su-body"):
            yield DataTable(id="su-items", cursor_type="row")
            with VerticalScroll(id="su-pane"):
                yield Static("Inspecting setup…", id="su-detail", markup=False)
        with HorizontalScroll(id="su-buttons"):
            for id, label in [
                ("inspect", "Inspect"),
                ("plan", "Preview plan"),
                ("apply", "Apply selected"),
                ("rebuild", "Rebuild paru"),
                ("toggle", "Enable/disable (e)"),
                ("upgrade", "Arch upgrade"),
                ("close", "Health"),
            ]:
                yield Button(label, id="su-" + id)
        yield Static(
            "e Enable/disable selected item · Viewing and planning never install packages.",
            id="su-status",
            markup=False,
        )

    def on_mount(self):
        self.set_class(self.app.size.width < 110, "narrow")
        self.query_one("#su-items", DataTable).add_columns("Setup", "Enabled", "State", "Summary")
        self.action_refresh()

    def on_resize(self, event):
        self.set_class(event.size.width < 110, "narrow")

    def controls(self):
        for id in ["inspect", "plan", "apply", "rebuild", "toggle", "upgrade"]:
            self.query_one("#su-" + id, Button).disabled = self.busy
        self.query_one("#su-apply", Button).disabled = (
            self.busy
            or not self.current_plan
            or bool(self.current_plan.blockers)
            or not self.current_plan.steps
        )
        self.query_one("#su-rebuild", Button).display = bool(
            self.selected and load().setup[self.selected].provider == "paru"
        )

    @work(exclusive=True, group="setup-inspect")
    async def action_refresh(self):
        if self.busy:
            return
        self.busy = True
        self.controls()
        try:
            observations = await asyncio.to_thread(inspect_all, None, True)
            self.rows = {r.id: r for r in observations}
            table = self.query_one("#su-items", DataTable)
            table.clear()
            settings = load()
            for row in observations:
                enabled = settings.setup[row.id].enabled
                table.add_row(
                    row.id,
                    Text("Yes" if enabled else "No", style="green" if enabled else "grey50"),
                    Text(row.status, style=COLORS[row.status]),
                    row.summary,
                    key=row.id,
                )
            if self.selected not in self.rows:
                self.selected = next(iter(self.rows), None)
            if self.selected:
                table.move_cursor(row=list(self.rows).index(self.selected))
        except Exception as error:
            self.query_one("#su-status", Static).update(
                str(error)
                if isinstance(error, Problem)
                else "Cannot inspect setup configuration."
            )
        finally:
            self.busy = False
            self.controls()
        if self.selected:
            self.preview()

    @on(DataTable.RowHighlighted, "#su-items")
    def highlighted(self, event):
        event.stop()
        self.selected = str(event.row_key.value)
        self.current_plan = None
        if not self.busy:
            self.preview()

    @work(exclusive=True, group="setup-plan")
    async def preview(self, action="apply"):
        if not self.selected:
            return
        self.seq += 1
        seq = self.seq
        id = self.selected
        try:
            item = load().setup[id]
            row = self.rows.get(id)
            lines = [
                id.upper(),
                (row.status + " · " + row.summary) if row else "",
                *([*row.details] if row else []),
                "",
            ]
            if item.enabled:
                value = await asyncio.to_thread(plan, id, action)
                if seq != self.seq:
                    return
                self.current_plan = value
                lines += ["Dependency plan:"] + [
                    f"{i}. {s.title}"
                    + (
                        " [" + ", ".join(s.options["packages"]) + "]"
                        if s.options.get("packages")
                        else ""
                    )
                    for i, s in enumerate(value.steps, 1)
                ]
                lines += ["BLOCKED: " + b for b in value.blockers]
                if not value.steps and not value.blockers:
                    lines += ["Already ready; applying makes no changes."]
            else:
                self.current_plan = None
                lines += ["Enable this item for this machine before applying."]
            events = [
                e
                for e in read_json(state_dir() / "actions.json", [])
                if e.get("id") == "setup:" + id
            ][-4:]
            lines += ["", "Recent actions:"] + [
                e["state"] + ": " + e["message"] for e in events
            ]
            self.query_one("#su-detail", Static).update(Text("\n".join(lines)))
        except Exception as error:
            self.current_plan = None
            self.query_one("#su-detail", Static).update(
                str(error) if isinstance(error, Problem) else "Cannot plan this setup."
            )
        self.controls()

    @on(Button.Pressed)
    def clicked(self, event):
        if not (event.button.id or "").startswith("su-"):
            return
        event.stop()
        key = event.button.id.removeprefix("su-")
        if key == "close":
            self.action_close()
        elif key == "inspect":
            self.action_refresh()
        elif key == "plan":
            self.preview()
        elif key == "rebuild":
            self.preview("rebuild")
        elif key == "apply":
            self.apply_selected()
        elif key == "toggle":
            self.action_toggle()
        elif key == "upgrade":
            self.app.launch(["review", "arch"])
            self.action_refresh()

    def action_toggle(self):
        if self.busy or not self.selected:
            return
        toggle_setup(self.selected, not load().setup[self.selected].enabled)
        self.action_refresh()

    def apply_selected(self):
        if (
            self.busy
            or not self.current_plan
            or self.current_plan.blockers
            or not self.current_plan.steps
        ):
            return
        self.app.launch(
            [
                "setup-apply",
                self.selected,
                "--action",
                self.current_plan.action,
                "--expected-plan",
                plan_token(self.current_plan),
            ]
        )
        self.action_refresh()

    def action_close(self):
        if self.busy:
            return
        self.seq += 1
        self.dismiss()
        self.app.repaint()
