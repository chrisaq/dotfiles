from __future__ import annotations
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable
import hashlib, os, shutil, tempfile
from ..config import load
from ..model import Action, Result, now
from ..util import Problem, run, lock, state_dir, atomic_json, read_json, signal_bar
from .model import Observation, Plan
from . import recipes


@dataclass
class Context:
    id: str
    item: object
    settings: object
    confirm: Callable[[str], bool] = lambda text: False
    display: Callable[[str], None] = print
    expected: dict = field(default_factory=dict)
    recovery: Path | None = None

    def run(self, args, **kwargs):
        return run(args, **kwargs)


def signature(settings):
    return hashlib.sha256(settings.model_dump_json().encode()).hexdigest()


def fingerprint(path):
    path = Path(path)
    if path.is_symlink():
        raise Problem("Refusing setup through a symlink: " + str(path))
    if not path.exists():
        return None
    if not path.is_file():
        raise Problem("Expected a regular setup file: " + str(path))
    return hashlib.sha256(path.read_bytes()).hexdigest()


def writable(path):
    path = Path(path).absolute()
    home = Path.home().absolute()
    if not path.is_relative_to(home):
        raise Problem(
            "Generated setup files must stay inside this home directory: " + str(path)
        )
    for p in [path, *path.parents]:
        if p == home.parent:
            break
        if p.is_symlink():
            raise Problem("Refusing a symlink setup path: " + str(p))
    return path


def replace_file(path, text, mode, ctx):
    path = writable(path)
    before = fingerprint(path)
    if str(path) in ctx.expected and before != ctx.expected[str(path)]:
        raise Problem("Setup file changed since review: " + str(path))
    if (
        path.exists()
        and path.read_text() == text
        and path.stat().st_mode & 0o777 == mode
    ):
        return
    if ctx.recovery is None:
        root = state_dir() / "setup/recovery"
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        ctx.recovery = Path(tempfile.mkdtemp(prefix="apply-", dir=root))
        ctx.recovery.chmod(0o700)
    if path.exists():
        target = ctx.recovery / path.relative_to(Path.home())
        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if not target.exists():
            shutil.copyfile(path, target)
            target.chmod(0o600)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, tmp = tempfile.mkstemp(prefix=".cq-setup-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        if fingerprint(path) != before:
            raise Problem("Setup file changed while writing: " + str(path))
        os.replace(tmp, path)
        ctx.expected[str(path)] = fingerprint(path)
    finally:
        Path(tmp).unlink(missing_ok=True)


def context(id, settings=None, **kwargs):
    settings = settings or load()
    if id not in settings.setup:
        raise Problem("Unknown setup item: " + id)
    return Context(id, settings.setup[id], settings, **kwargs)


def inspect_one(id, settings=None, save=False):
    ctx = context(id, settings)
    if not ctx.item.enabled:
        result = Observation(
            id=id, status="disabled", summary="Disabled on this machine"
        )
    else:
        try:
            result = recipes.get(ctx.item.provider).inspect(ctx)
        except Exception as error:
            result = Observation(
                id=id,
                status="unavailable",
                summary=str(error)
                if isinstance(error, Problem)
                else "Cannot inspect setup; check configuration/access.",
            )
    if save:
        atomic_json(state_dir() / "setup/results" / f"{id}.json", result.model_dump())
    return result


def inspect_all(settings=None, save=False):
    settings = settings or load()
    return [inspect_one(id, settings, save) for id in settings.setup]


def ordered(steps):
    # Consolidate repository requirements before dependency ordering.
    from .model import Step

    pkgsteps = [s for s in steps if s.kind == "pacman"]
    mapping = {s.id: "packages:repos" for s in pkgsteps}
    rest = [s.model_copy(deep=True) for s in steps if s.kind != "pacman"]
    if pkgsteps:
        rest.insert(
            0,
            Step(
                id="packages:repos",
                kind="pacman",
                title="Install repository prerequisites",
                options={
                    "packages": sorted(
                        {n for s in pkgsteps for n in s.options["packages"]}
                    )
                },
            ),
        )
    nodes = {}
    for step in rest:
        step.requires = list(dict.fromkeys(mapping.get(r, r) for r in step.requires))
        if step.id in nodes and step != nodes[step.id]:
            raise Problem("Conflicting setup dependency: " + step.id)
        nodes[step.id] = step
    out = []
    visiting = set()
    done = set()

    def visit(id):
        if id in done:
            return
        if id in visiting:
            raise Problem("Setup dependency cycle: " + id)
        if id not in nodes:
            raise Problem("Missing setup dependency: " + id)
        visiting.add(id)
        for dep in nodes[id].requires:
            visit(dep)
        visiting.remove(id)
        done.add(id)
        out.append(nodes[id])

    for id in nodes:
        visit(id)
    return out


def plan(id, action="apply", settings=None):
    ctx = context(id, settings)
    if not ctx.item.enabled:
        raise Problem("Enable this setup item first.")
    result = Plan(id=id, action=action, settings_hash=signature(ctx.settings))
    try:
        steps, blockers, changes = recipes.get(ctx.item.provider).plan(ctx, action)
        result.steps = ordered(steps)
        result.blockers = blockers
        result.changes = changes
        for path in recipes.get(ctx.item.provider).watched(ctx):
            writable(path)
            result.fingerprints[str(path)] = fingerprint(path)
    except Problem as error:
        result.blockers.append(str(error))
    return result


def apply(plan, confirm, display=print):
    from ..engine import log_event

    settings = load()
    if signature(settings) != plan.settings_hash:
        raise Problem("Configuration changed after planning; review a fresh plan.")
    ctx = context(
        plan.id,
        settings,
        confirm=confirm,
        display=display,
        expected=dict(plan.fingerprints),
    )
    if plan.blockers:
        raise Problem("Resolve setup blockers first: " + "; ".join(plan.blockers))
    for name, value in plan.fingerprints.items():
        if fingerprint(name) != value:
            raise Problem("A setup file changed; review a fresh plan: " + name)
    with lock("setup-apply"):
        for step in plan.steps:
            try:
                if signature(load()) != plan.settings_hash:
                    raise Problem("Configuration changed during setup; re-plan.")
                display(step.title)
                recipes.get(ctx.item.provider).apply(ctx, step)
                log_event(
                    {
                        "id": "setup:" + plan.id,
                        "state": "completed",
                        "message": step.title,
                    }
                )
            except Exception as error:
                message = (
                    str(error)
                    if isinstance(error, Problem)
                    else "Setup step failed; inspect foreground output."
                )
                log_event(
                    {
                        "id": "setup:" + plan.id,
                        "state": "blocked",
                        "message": step.title + ": " + message,
                    }
                )
                inspect_one(plan.id, settings, True)
                signal_bar(settings.waybar_signal)
                raise Problem(message) from None
    result = inspect_one(plan.id, settings, True)
    signal_bar(settings.waybar_signal)
    if result.status != "ready":
        raise Problem(
            "Applied steps, but verification still reports "
            + result.status
            + ": "
            + "; ".join(result.details)
        )
    return result


def as_health(obs):
    states = {
        "ready": "ok",
        "required": "warning",
        "blocked": "warning",
        "unavailable": "unknown",
        "disabled": "disabled",
        "unsupported": "disabled",
    }
    return Result(
        id="setup:" + obs.id,
        state=states[obs.status],
        summary=obs.summary,
        details=obs.details,
        checked_at=obs.checked_at,
        actions=[Action(id="setup", label="Open setup checklist")],
    )


def visible(settings):
    rows = []
    for id, item in settings.setup.items():
        if not item.enabled or not item.waybar:
            continue
        data = read_json(state_dir() / "setup/results" / f"{id}.json")
        obs = (
            Observation.model_validate(data)
            if data
            else Observation(
                id=id,
                status="unavailable",
                summary="Setup has not been inspected",
                checked_at=0,
            )
        )
        if obs.status in ("disabled", "unsupported"):
            continue
        row = as_health(obs)
        if now() - obs.checked_at > 900:
            row.stale = True
            row.state = "unknown"
            row.details.insert(0, "Setup observation is stale; refresh Setup.")
        rows.append(row)
    return rows
