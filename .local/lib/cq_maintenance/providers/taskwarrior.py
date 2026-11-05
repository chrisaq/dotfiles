"""Taskwarrior sync freshness; inspecting never contacts the sync server."""

import hashlib, math, shutil
from pathlib import Path
from ..model import now
from ..util import Problem, require, atomic_json, read_json, state_dir
from .base import action


def record_path(data):
    key = hashlib.sha256(str(Path(data).expanduser().resolve()).encode()).hexdigest()
    return state_dir() / "taskwarrior" / (key + ".json")


def record_success(data):
    # No tasks, URLs, IDs, encryption secrets or hook stdin enter this record.
    atomic_json(record_path(data), {"last_success": now()})


def locations(ctx):
    if not shutil.which("task"):
        raise Problem(
            "Taskwarrior is missing; install task or disable this check on this machine."
        )
    values = []
    for name in ["data.location", "hooks.location"]:
        text = require(
            ctx.run(
                ["task", "rc.hooks=off", "rc.verbose=nothing", "_get", "rc." + name],
                timeout=5,
            )
        ).stdout.strip()
        values.append(Path(text).expanduser().resolve() if text else None)
    data, hooks = values
    if not data or not data.is_dir():
        raise Problem(
            "Taskwarrior data directory is missing; restore your configuration first."
        )
    return data, hooks or data / "hooks"


def source():
    return Path.home() / ".local/bin/cq_task-sync-hook"


def hook_path(folder):
    return folder / "on-exit.cq-maintenance-sync"


def hook_ready(folder):
    path = hook_path(folder)
    return (
        path.is_symlink()
        and path.resolve() == source().resolve()
        and source().is_file()
    )


def check(ctx):
    data, folder = locations(ctx)
    stamp = read_json(record_path(data), {}).get("last_success")
    if (
        not isinstance(stamp, (int, float))
        or not math.isfinite(stamp)
        or stamp <= 0
        or stamp > now() + 60
    ):
        stamp = None
    age = max(0, now() - stamp) if stamp else None
    threshold = int(ctx.options.get("stale_seconds", 86400))
    if threshold <= 0:
        raise Problem("Taskwarrior stale_seconds must be positive")
    state = "warning" if age is None or age >= threshold else "ok"
    summary = (
        "No successful sync recorded"
        if age is None
        else f"Last successful sync {int(age // 3600)}h {int(age % 3600 // 60)}m ago"
    )
    details = [
        "Warn after " + str(threshold // 3600) + " hours without a successful sync."
    ]
    actions = [action("Sync Taskwarrior")]
    if not hook_ready(folder):
        state = "warning"
        details.append(
            "Manual sync tracking needs initialization. Open Setup → taskwarrior."
        )
        actions.append(
            action("Initialize manual sync tracking", safe=False, id="setup")
        )
    if age is None:
        details.append(
            "Run a successful sync to establish the local timestamp; old database times are not evidence of sync."
        )
    return ctx.result(
        state, summary, details=details, last_success=stamp, actions=actions
    )


def execute(ctx, id):
    if id == "setup":
        require(
            ctx.run(
                [
                    Path.home() / ".local/bin/cq_maintenance",
                    "setup-apply",
                    "taskwarrior",
                ],
                foreground=True,
                timeout=120,
            )
        )
        return "Taskwarrior sync tracking setup reviewed"
    if id != "fix":
        raise Problem("Unsupported Taskwarrior action")
    data, _ = locations(ctx)
    result = ctx.run(["task", "sync"], foreground=True, timeout=300)
    if result.returncode:
        raise Problem(
            "Taskwarrior sync failed; the last successful sync time was preserved. Inspect the foreground output."
        )
    record_success(data)
    return "Taskwarrior sync completed"


def open(ctx):
    return [
        Path.home() / ".local/bin/cq_maintenance",
        "tui",
        "--view",
        "setup",
        "--select",
        "taskwarrior",
    ]
