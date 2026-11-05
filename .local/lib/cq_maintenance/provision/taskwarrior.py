"""Install a local link to the portable Taskwarrior success hook."""

from .model import Observation, Step
from ..providers import taskwarrior as tasks
from ..util import Problem


def inspect(ctx):
    _, folder = tasks.locations(ctx)
    path = tasks.hook_path(folder)
    if tasks.hook_ready(folder):
        return Observation(
            id=ctx.id, status="ready", summary="Manual sync tracking installed"
        )
    if path.exists() or path.is_symlink():
        return Observation(
            id=ctx.id,
            status="blocked",
            summary="Foreign Taskwarrior hook",
            details=["Inspect ownership of " + str(path)],
        )
    if not tasks.source().is_file():
        return Observation(
            id=ctx.id,
            status="blocked",
            summary="Distribute the cq_task-sync-hook script first",
        )
    return Observation(
        id=ctx.id, status="required", summary="Install manual sync success tracking"
    )


def plan(ctx, action):
    if action != "apply":
        raise Problem("Unsupported Taskwarrior setup action")
    observation = inspect(ctx)
    if observation.status == "blocked":
        return [], [observation.summary, *observation.details], []
    if observation.status == "ready":
        return [], [], []
    _, folder = tasks.locations(ctx)
    from .core import writable

    path = writable(tasks.hook_path(folder))
    return (
        [
            Step(
                id=ctx.id,
                kind="taskwarrior",
                title="Link Taskwarrior on-exit sync success hook",
                options={"path": str(path)},
            )
        ],
        [],
        [str(path) + " → " + str(tasks.source())],
    )


def watched(ctx):
    return [tasks.source()]


def apply(ctx, step):
    from .core import writable

    _, folder = tasks.locations(ctx)
    path = tasks.hook_path(folder)
    if str(path) != step.options["path"]:
        raise Problem("Taskwarrior hook location changed; re-plan.")
    if tasks.hook_ready(folder):
        return
    path = writable(path)
    if path.exists() or path.is_symlink():
        raise Problem("Refusing to replace an existing Taskwarrior hook.")
    folder.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.symlink_to(tasks.source())
