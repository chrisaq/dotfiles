"""Shared Syncthing conflict workbench. Plaintext secrets never enter recovery files."""

from __future__ import annotations
import asyncio, difflib, fcntl, hashlib, importlib.machinery, importlib.util, json, os, re, stat, subprocess, sys, tempfile, time
from dataclasses import dataclass
from pathlib import Path
import xml.etree.ElementTree as ET
from textual import on, work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.screen import ModalScreen
from textual.theme import Theme
from textual.widgets import Button, Input, Label, ListItem, ListView, Static, TextArea
from rich.text import Text

PATTERN = re.compile(r"^(.*?)\.sync-conflict-(\d{8}-\d{6})-([A-Z0-9]+)(\..*)?$")
LIMIT = 2 * 1024 * 1024


class ConflictError(Exception):
    pass


def digest(path: Path) -> str | None:
    if path.is_symlink():
        raise ConflictError("Symlink files are not supported.")
    if not path.exists():
        return None
    if not path.is_file():
        raise ConflictError("Expected a regular file.")
    if path.stat().st_size > LIMIT:
        raise ConflictError("File exceeds the 2 MiB review limit; use another tool.")
    return hashlib.sha256(path.read_bytes()).hexdigest()


@dataclass(frozen=True)
class Conflict:
    root: Path
    copy: Path
    current: Path
    timestamp: str
    device: str

    @property
    def label(self):
        return str(self.current.relative_to(self.root))

    @property
    def encrypted(self):
        return self.copy.suffix == ".gpg"


@dataclass
class Comparison:
    conflict: Conflict
    current_hash: str | None
    copy_hash: str
    left: str
    right: str


def discover(roots: list[Path]) -> list[Conflict]:
    found = {}
    visited = 0
    for root in roots:
        root = root.expanduser().resolve()
        if not root.is_dir():
            continue
        for base, dirs, files in os.walk(root, followlinks=False):
            dirs[:] = sorted(
                d
                for d in dirs
                if d not in {".git", ".stversions", ".stfolder"}
                and not (Path(base) / d).is_symlink()
            )
            for name in sorted(files):
                visited += 1
                if visited > 300000:
                    raise ConflictError(
                        "Scan limit reached. Choose a smaller --root; results were not silently truncated."
                    )
                match = PATTERN.match(name)
                if not match:
                    continue
                copy = Path(base) / name
                if copy.is_symlink():
                    continue
                current = copy.with_name(match[1] + (match[4] or ""))
                if current.is_symlink():
                    continue
                found[copy] = Conflict(root, copy, current, match[2], match[3])
    return sorted(found.values(), key=lambda c: (str(c.current), c.timestamp))


def default_roots() -> list[Path]:
    for path in [
        Path.home() / ".local/state/syncthing/config.xml",
        Path.home() / ".config/syncthing/config.xml",
    ]:
        if path.is_file():
            xml = ET.parse(path).getroot()
            return [
                Path(f.get("path", "")).expanduser()
                for f in xml.findall("folder")
                if f.get("path")
            ]
    return [Path.home() / "Sync"]


class Resolver:
    def __init__(self, store: Path, backend):
        self.store = store.expanduser().resolve()
        self.backend = backend

    def entry(self, path: Path) -> str:
        try:
            relative = path.relative_to(self.store)
        except ValueError:
            raise ConflictError(
                "Encrypted comparison requires a file inside the selected password store."
            ) from None
        return str(relative.with_suffix(""))

    def validate(self, c: Conflict):
        for p in [c.copy, c.current]:
            try:
                p.relative_to(c.root)
            except ValueError:
                raise ConflictError("File is outside the selected root.") from None
            for part in [p, *p.parents]:
                if part == c.root.parent:
                    break
                if part.is_symlink():
                    raise ConflictError("Symlink paths are not supported.")

    def load(self, c: Conflict) -> Comparison:
        self.validate(c)
        a, b = digest(c.current), digest(c.copy)
        if b is None:
            raise ConflictError("The conflict copy has disappeared. Rescan.")
        try:
            if c.encrypted:
                left = self.backend.read(self.entry(c.current)).raw if a else ""
                right = self.backend.read(self.entry(c.copy)).raw
            else:
                left = c.current.read_bytes().decode("utf-8") if a else ""
                right = c.copy.read_bytes().decode("utf-8")
                if "\x00" in left + right:
                    raise ConflictError(
                        "Binary file: automatic text resolution is disabled."
                    )
        except ConflictError:
            raise
        except Exception:
            raise ConflictError(
                "Cannot read/decrypt this pair. Check GPG access or file format; no changes made."
            ) from None
        if len(left.encode()) > LIMIT or len(right.encode()) > LIMIT:
            raise ConflictError("Decrypted text exceeds the review limit.")
        result = Comparison(c, a, b, left, right)
        self.check(result)
        return result

    def check(self, pair: Comparison):
        self.validate(pair.conflict)
        if (
            digest(pair.conflict.current) != pair.current_hash
            or digest(pair.conflict.copy) != pair.copy_hash
        ):
            raise ConflictError(
                "A file changed since this comparison. Reload before resolving."
            )

    def resolve(self, pair: Comparison, choice: str, merged: str | None = None) -> Path:
        if choice not in {"current", "alternative", "merged", "archive"}:
            raise ConflictError("Invalid resolution.")
        if choice == "current" and pair.current_hash is None:
            raise ConflictError(
                "No current file. Restore or explicitly archive the alternative."
            )
        if choice == "archive" and pair.current_hash is not None:
            raise ConflictError("Use keep current when the normal file exists.")
        if choice == "merged" and merged is None:
            raise ConflictError("No reviewed merge draft.")
        if choice == "merged" and len(merged.encode("utf-8")) > LIMIT:
            raise ConflictError("Merge result exceeds the 2 MiB limit.")
        state = (
            Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
            / "cq/conflicts"
        )
        state.mkdir(parents=True, exist_ok=True, mode=0o700)
        state.chmod(0o700)
        lockname = (
            hashlib.sha256(str(pair.conflict.current).encode()).hexdigest() + ".lock"
        )
        with (state / lockname).open("a") as lock:
            os.chmod(lock.name, 0o600)
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise ConflictError(
                    "Another resolver is working on this file."
                ) from None
            self.check(pair)
            backup = Path(tempfile.mkdtemp(prefix="resolved-", dir=state))
            backup.chmod(0o700)
            c = pair.conflict
            for name, p in [("current", c.current), ("alternative", c.copy)]:
                if p.exists():
                    target = backup / (name + p.suffix)
                    target.write_bytes(p.read_bytes())
                    target.chmod(0o600)
            manifest = {
                "current": str(c.current),
                "alternative": str(c.copy),
                "choice": choice,
                "current_sha256": pair.current_hash,
                "alternative_sha256": pair.copy_hash,
                "completed": False,
            }
            record = backup / "resolution.json"
            record.write_text(json.dumps(manifest, indent=2))
            record.chmod(0o600)
            self.check(pair)
            wrote = False
            try:
                if choice not in {"current", "archive"}:
                    content = pair.right if choice == "alternative" else merged
                    if c.encrypted:
                        self.backend.write(
                            self.entry(c.current),
                            content,
                            message="Resolve Syncthing conflict",
                        )
                    else:
                        mode = (
                            stat.S_IMODE(c.current.stat().st_mode)
                            if c.current.exists()
                            else 0o600
                        )
                        fd, tmp = tempfile.mkstemp(
                            prefix=".cq-conflict-", dir=c.current.parent
                        )
                        try:
                            with os.fdopen(
                                fd, "w", encoding="utf-8", newline=""
                            ) as stream:
                                stream.write(content)
                                stream.flush()
                                os.fsync(stream.fileno())
                            os.chmod(tmp, mode)
                            self.check(pair)
                            os.replace(tmp, c.current)
                        finally:
                            if os.path.exists(tmp):
                                os.unlink(tmp)
                    wrote = True
                # Never remove a changed alternative after a slow GPG operation.
                if digest(c.copy) != pair.copy_hash:
                    raise ConflictError(
                        "Alternative changed during save; retained for review."
                    )
                if not wrote and digest(c.current) != pair.current_hash:
                    raise ConflictError("Current file changed; retained alternative.")
                if c.encrypted:
                    self.backend.run("delete", "--force", self.entry(c.copy))
                else:
                    c.copy.unlink()
                manifest["completed"] = True
                record.write_text(json.dumps(manifest, indent=2))
            except Exception:
                raise ConflictError(
                    "Resolution did not complete. Recovery copies were retained; reload both versions before retrying."
                ) from None
            return backup


def load_pass_ui():
    name = "cq_pass_conflict_host"
    if name in sys.modules:
        return sys.modules[name]
    loader = importlib.machinery.SourceFileLoader(
        name, str(Path.home() / ".local/bin/cq_pass-tui")
    )
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    loader.exec_module(module)
    return module


def merge_editor(ui, pair):
    """Reuse the password editor, keeping the alternative visible beside the draft."""

    class MergeEditor(ui.EditorScreen):
        CSS = """
        #merge-body { height: 1fr; }
        .hidden { display: none; }
        #ed-area { width: 1fr; margin-right: 1; }
        #merge-source { width: 1fr; height: 1fr; border: round $secondary; }
        """

        def __init__(self, text, alternative, had_current):
            super().__init__(text, title="Conflict result")
            self.alternative = alternative
            self.had_current = had_current

        def compose(self):
            with Vertical(id="ed-box"):
                yield Label(
                    "Merge result · edit left, compare alternative right",
                    id="ed-head",
                    markup=False,
                )
                yield Input(
                    placeholder="Find in result · Ctrl+G close",
                    id="ed-find",
                    classes="hidden",
                )
                with Horizontal(id="merge-body"):
                    yield ui.ShellTextArea(
                        self._text,
                        language="yaml",
                        id="ed-area",
                        show_line_numbers=True,
                        tab_behavior="indent",
                        soft_wrap=False,
                    )
                    yield TextArea(
                        self.alternative,
                        read_only=True,
                        show_line_numbers=True,
                        soft_wrap=False,
                        id="merge-source",
                    )
                yield Static(
                    "Ctrl+S review result · Esc cancel · Ctrl+R find · F1 editor keys",
                    id="ed-foot",
                )

        def on_mount(self):
            super().on_mount()
            self.query_one("#ed-area").border_title = (
                "Result · starts from current"
                if self.had_current
                else "Result · restores alternative"
            )
            source = self.query_one("#merge-source", TextArea)
            source.border_title = "Alternative · read-only"
            ui.theme_editor(source, self.app.theme)

        def on_unmount(self):
            self._text = ""
            self.alternative = ""

    return MergeEditor(
        pair.left if pair.current_hash else pair.right,
        pair.right,
        pair.current_hash is not None,
    )


class ConflictScreen(ModalScreen[None]):
    CSS = """
    ConflictScreen { background: $background; }
    #cf-top { height: 3; background: $surface; padding: 0 1; }
    #cf-brand { width: 1fr; content-align: left middle; color: $primary; text-style: bold; }
    #cf-top Button { min-width: 10; }
    #cf-filter { margin: 0 1; height: 3; }
    #cf-body { height: 1fr; padding: 0 1; }
    #cf-list { width: 28%; min-width: 22; border: round $primary-muted; margin-right: 1; }
    #cf-list:focus-within { border: round $primary; }
    #cf-list Label { padding: 0 1; }
    #cf-review { width: 1fr; }
    #cf-meta { height: auto; max-height: 5; padding: 0 1; color: $text-muted; }
    #cf-panes { height: 1fr; }
    #cf-panes TextArea { width: 1fr; border: round $secondary-muted; }
    #cf-left { margin-right: 1; }
    #cf-diff-scroll { height: 1fr; border: round $secondary; display: none; }
    #cf-diff { height: auto; }
    #cf-actions { height: 3; padding: 0 1; }
    #cf-actions Button { width: 1fr; min-width: 12; margin-right: 1; }
    #cf-status { height: auto; max-height: 3; padding: 0 1; background: $panel; }
    #cf-help { height: 1; color: $text-muted; padding: 0 1; }
    """
    BINDINGS = [
        Binding("escape", "close", "Back", priority=True),
        Binding("ctrl+r", "reload", "Rescan", priority=True),
        Binding("ctrl+l", "lock", "Lock", priority=True),
        Binding("v", "reveal", "Reveal"),
        Binding("d", "diff", "Diff"),
        Binding("ctrl+t", "theme", "Theme", priority=True),
    ]

    def __init__(self, roots, resolver, ui, *, reveal_timeout=30):
        super().__init__()
        self.roots = roots
        self.resolver = resolver
        self.ui = ui
        self.timeout = max(1, reveal_timeout)
        self.conflicts = []
        self.filtered = []
        self.pair = None
        self.seq = 0
        self.revealed = False
        self.until = 0
        self.diff_mode = False
        self.busy = False
        self.loading = False
        self.draft = None

    def compose(self) -> ComposeResult:
        with Horizontal(id="cf-top"):
            yield Static("◈  SYNC CONFLICTS  /  workbench", id="cf-brand")
            yield Button("Theme", id="cf-theme")
            yield Button("Rescan", id="cf-reload")
            yield Button("Back", id="cf-close")
        yield Input(
            placeholder="Filter by path, conflict date or device…", id="cf-filter"
        )
        with Horizontal(id="cf-body"):
            yield ListView(id="cf-list")
            with Vertical(id="cf-review"):
                yield Static(
                    "Select an alternative to compare. Multiple copies are listed separately.",
                    id="cf-meta",
                    markup=False,
                )
                with Horizontal(id="cf-panes"):
                    yield TextArea(
                        "",
                        read_only=True,
                        show_line_numbers=True,
                        soft_wrap=False,
                        id="cf-left",
                    )
                    yield TextArea(
                        "",
                        read_only=True,
                        show_line_numbers=True,
                        soft_wrap=False,
                        id="cf-right",
                    )
                with VerticalScroll(id="cf-diff-scroll"):
                    yield Static("", id="cf-diff", markup=False)
        with Horizontal(id="cf-actions"):
            yield Button("Keep current", id="cf-current", disabled=True)
            yield Button("Use alternative", id="cf-alternative", disabled=True)
            yield Button("Edit result…", id="cf-edit", disabled=True)
            yield Button("Reveal", id="cf-reveal", disabled=True)
            yield Button("Show diff", id="cf-diff-button")
        yield Static(
            "Scanning paths only; secret contents are read only when selected.",
            id="cf-status",
            markup=False,
        )
        yield Static(
            "Ctrl+R rescan · v reveal (timed) · Ctrl+L lock · d diff · Ctrl+T theme · Esc back",
            id="cf-help",
        )

    def on_mount(self):
        self.query_one("#cf-list").border_title = "Alternatives / paths"
        self.query_one("#cf-left").border_title = "Current file"
        self.query_one("#cf-right").border_title = "Preserved alternative"
        self.set_interval(0.5, self.tick)
        self.action_reload()

    def status(self, message):
        self.query_one("#cf-status", Static).update(message)

    def buttons(self):
        for key in ["current", "alternative", "edit", "reveal"]:
            self.query_one("#cf-" + key, Button).disabled = (
                self.busy or self.pair is None
            )

    def erase(self):
        self.pair = None
        self.draft = None
        self.revealed = False
        for key in ["cf-left", "cf-right"]:
            self.query_one("#" + key, TextArea).load_text("")
        self.query_one("#cf-diff", Static).update("")
        self.buttons()

    @work(exclusive=True, group="conflict-scan")
    async def action_reload(self):
        if self.busy:
            return
        self.seq += 1
        self.erase()
        try:
            self.conflicts = await asyncio.to_thread(discover, self.roots)
            await self.filter_list()
            self.status(
                f"{len(self.conflicts)} preserved alternatives · choose a pair to compare; no automatic winner."
            )
        except Exception as e:
            self.status(
                str(e)
                if isinstance(e, ConflictError)
                else "Cannot scan folders. Check access."
            )

    async def filter_list(self):
        self.loading = True
        try:
            query = self.query_one("#cf-filter", Input).value.lower()
            self.filtered = [
                c
                for c in self.conflicts
                if query in (str(c.copy) + " " + c.timestamp).lower()
            ]
            view = self.query_one("#cf-list", ListView)
            await view.clear()
            await view.extend(
                [
                    ListItem(
                        Label(Text(c.label + "\n" + c.timestamp + " · " + c.device))
                    )
                    for c in self.filtered
                ]
            )
            view.index = None
        finally:
            self.loading = False

    @on(Input.Changed, "#cf-filter")
    async def filter_changed(self):
        if self.busy:
            return
        self.seq += 1
        self.erase()
        await self.filter_list()

    @on(ListView.Selected, "#cf-list")
    def selected(self, event):
        if self.busy or self.loading or event.list_view.index is None:
            return
        self.open_pair(self.filtered[event.list_view.index])

    @work(exclusive=True, group="conflict-load")
    async def open_pair(self, c):
        if self.busy:
            return
        self.seq += 1
        seq = self.seq
        self.erase()
        self.status("Reading selected pair…")
        try:
            pair = await asyncio.to_thread(self.resolver.load, c)
            if seq != self.seq or not self.is_mounted:
                return
            self.pair = pair
            self.paint()
            self.status(
                "Identical plaintext; keep current to archive the duplicate."
                if pair.left == pair.right
                else "Contents differ. Compare, choose a version, or edit a result. Each save requires confirmation."
            )
        except Exception as e:
            if seq == self.seq:
                self.status(
                    str(e)
                    if isinstance(e, ConflictError)
                    else "Could not open this pair."
                )

    def paint(self):
        if not self.pair:
            return
        p = self.pair
        c = p.conflict
        hidden = c.encrypted and not self.revealed
        left = (
            p.left if not hidden else "\n".join("••••••••" for _ in p.left.splitlines())
        )
        right = (
            p.right
            if not hidden
            else "\n".join("••••••••" for _ in p.right.splitlines())
        )
        self.query_one("#cf-left", TextArea).load_text(left)
        self.query_one("#cf-right", TextArea).load_text(right)
        for key in ["cf-left", "cf-right"]:
            area = self.query_one("#" + key, TextArea)
            area.language = "json" if c.current.suffix == ".json" else "yaml"
            self.ui.theme_editor(area, self.app.theme)
        self.query_one("#cf-meta", Static).update(
            f"{c.current}\nAlternative: {c.copy.name}\n"
            + (
                "Current file is absent · use alternative to restore."
                if p.current_hash is None
                else (
                    "Encrypted · masked until revealed."
                    if hidden
                    else "Current file left · preserved alternative right."
                )
            )
        )
        diff = (
            "Reveal to inspect decrypted changes."
            if hidden
            else "".join(
                difflib.unified_diff(
                    p.left.splitlines(keepends=True),
                    p.right.splitlines(keepends=True),
                    fromfile="current",
                    tofile="alternative",
                )
            )
            or "No content differences."
        )
        self.query_one("#cf-diff", Static).update(
            Text(diff)
            if hidden
            else self.ui.syntax(diff, "diff", self.app.theme, word_wrap=False)
        )
        self.query_one("#cf-reveal", Button).label = (
            "Mask" if self.revealed else "Reveal"
        )
        self.query_one("#cf-reveal", Button).display = c.encrypted
        self.query_one("#cf-current", Button).label = (
            "Archive orphan" if p.current_hash is None else "Keep current"
        )
        self.query_one("#cf-alternative", Button).label = (
            "Restore alternative" if p.current_hash is None else "Use alternative"
        )
        self.buttons()

    def action_reveal(self):
        if self.pair and not self.busy:
            self.revealed = not self.revealed
            self.until = time.monotonic() + self.timeout
            self.paint()

    def tick(self):
        if self.revealed and time.monotonic() >= self.until:
            self.revealed = False
            self.paint()

    def action_lock(self):
        if self.busy:
            self.revealed = False
            self.paint()
            return
        self.seq += 1
        self.erase()
        self.status(
            "Locked · plaintext buffers forgotten. Enter on an alternative to reload."
        )

    def action_diff(self):
        self.diff_mode = not self.diff_mode
        self.query_one("#cf-panes").display = not self.diff_mode
        self.query_one("#cf-diff-scroll").display = self.diff_mode
        self.query_one("#cf-diff-button", Button).label = (
            "Side by side" if self.diff_mode else "Show diff"
        )

    def action_theme(self):
        self.app.theme = "latte" if self.app.theme == "macchiato" else "macchiato"
        self.paint()

    def action_close(self):
        if self.busy:
            self.status("Finish the current operation first.")
            return
        self.seq += 1
        self.erase()
        self.dismiss(None)

    def on_unmount(self):
        self.seq += 1
        self.pair = None
        self.draft = None

    @on(Button.Pressed)
    def clicked(self, event):
        if not (event.button.id or "").startswith("cf-"):
            return
        event.stop()
        key = event.button.id.removeprefix("cf-")
        if key in {"current", "alternative", "edit"}:
            self.resolve_choice(key)
        elif key == "diff-button":
            self.action_diff()
        else:
            getattr(self, "action_" + key)()

    @work(group="conflict-resolve")
    async def resolve_choice(self, choice):
        if self.busy or self.pair is None:
            return
        self.busy = True
        self.buttons()
        pair = self.pair
        if choice == "current" and pair.current_hash is None:
            choice = "archive"
        try:
            merged = None
            if choice == "edit":
                # An editor explicitly reveals plaintext; mask the comparison before entering it.
                if pair.conflict.encrypted and not await self.app.push_screen_wait(
                    self.ui.ConfirmScreen(
                        "Open decrypted editor?",
                        "The result editor will display plaintext. Nothing is saved until you confirm the final resolution.",
                        danger=False,
                    )
                ):
                    return
                merged = await self.app.push_screen_wait(merge_editor(self.ui, pair))
                if merged is None:
                    return
                choice = "merged"
            if not await self.app.push_screen_wait(
                self.ui.ConfirmScreen(
                    "Resolve this alternative?",
                    f"{pair.conflict.current}\n\n"
                    + (
                        "Keep the current file."
                        if choice == "current"
                        else "Keep the normal file absent; archive this orphan alternative."
                        if choice == "archive"
                        else "Write the reviewed result to the normal filename."
                    )
                    + "\nPreserve recovery copies outside Sync, then remove only this alternative. Other copies remain for review.",
                )
            ):
                return
            backup = await asyncio.to_thread(
                self.resolver.resolve, pair, choice, merged
            )
            self.seq += 1
            self.erase()
            self.conflicts = await asyncio.to_thread(discover, self.roots)
            await self.filter_list()
            self.status(
                f"Resolved. Recovery: {backup} · {len(self.conflicts)} alternatives remain."
            )
            # Refresh cached Waybar status without waiting for a periodic collector.
            tool = Path.home() / ".local/bin/cq_maintenance"
            if tool.exists():
                subprocess.Popen(
                    [str(tool), "check", "syncthing", "--quiet"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True,
                )
        except Exception as e:
            self.status(
                str(e)
                if isinstance(e, ConflictError)
                else "Resolution failed; reload before retrying. Recovery copies are retained."
            )
        finally:
            self.busy = False
            self.buttons()


class ConflictApp(App):
    TITLE = "cq_sync-conflicts"

    def __init__(self, roots, store, ui, settings, backend=None):
        super().__init__()
        self.ui = ui
        self.roots = roots
        self.backend = backend or ui.GopassClient(store)
        self.resolver = Resolver(store, self.backend)
        self.settings = settings
        for name, p in ui.PALETTES.items():
            self.register_theme(
                Theme(
                    name=name,
                    primary=p["blue"],
                    secondary=p["mauve"],
                    accent=p["mauve"],
                    foreground=p["text"],
                    background=p["base"],
                    surface=p["mantle"],
                    panel=p["surface"],
                    success=p["green"],
                    warning=p["yellow"],
                    error=p["red"],
                    dark=name == "macchiato",
                )
            )
        self.theme = settings.theme

    def on_mount(self):
        self.push_screen(
            ConflictScreen(
                self.roots,
                self.resolver,
                self.ui,
                reveal_timeout=self.settings.reveal_timeout,
            ),
            lambda _: self.exit(),
        )

    def on_app_blur(self):
        if self.settings.mask_on_blur:
            for screen in self.screen_stack:
                if isinstance(screen, ConflictScreen):
                    screen.action_lock()

    def on_unmount(self):
        self.backend.close()
