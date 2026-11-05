"""Built-in setup providers. Package requirements are data, not shell fragments."""

import json, shutil
from pathlib import Path
from ..util import Problem
from .model import Observation, Step
from . import packages, browser, units


MAIL_PACKAGES = {
    "uv": "uv",
    "systemctl": "systemd",
    "neomutt": "neomutt",
    "mbsync": "isync",
    "notmuch": "notmuch",
    "afew": "afew",
    "msmtp": "msmtp",
    "vdirsyncer": "vdirsyncer",
    "khard": "khard",
    "gopass": "gopass",
    "gpg": "gnupg",
    "fzf": "fzf",
    "lynx": "lynx",
    "xdg-open": "xdg-utils",
    "vobject": "python-vobject",
    "reportlab": "python-reportlab",
    "notmuch2": "python-notmuch2",
}


def mail_components(settings):
    return sorted(
        {
            c.options.get("component", name)
            for name, c in settings.checks.items()
            if c.enabled
            and c.provider == "mail"
            and c.options.get("expected_timer", True)
            and c.options.get("component", name) in ("mail", "contacts")
        }
    )


def timer_issues(ctx, timers):
    issues = []
    for timer in timers:
        for verb, word in [("is-enabled", "enabled"), ("is-active", "active")]:
            result = ctx.run(["systemctl", "--user", verb, timer], timeout=5)
            if result.returncode or result.stdout.strip() not in (
                word,
                "enabled-runtime",
            ):
                issues.append(timer + " is not " + word)
    return issues


def mail_info(ctx):
    components = mail_components(ctx.settings)
    if not components:
        return components, {}, [], []
    helper = Path.home() / ".local/bin/cq_mailctl"
    if not helper.exists():
        return (
            components,
            {},
            [],
            ["cq_mailctl is missing; distribute your dotfiles first."],
        )
    result = ctx.run([helper, "setup", "--check", "--json"], timeout=45)
    try:
        data = json.loads(result.stdout)
    except (ValueError, TypeError):
        return (
            components,
            {},
            [],
            [
                "Mail settings/setup inspection unavailable; restore private settings and inspect cq_mailctl setup --check."
            ],
        )
    missing = data.get("missing_prerequisites", [])
    pkgs = [MAIL_PACKAGES[x] for x in missing if x in MAIL_PACKAGES]
    blockers = [
        "Restore/configure mail prerequisite: " + x
        for x in missing
        if x not in MAIL_PACKAGES
    ]
    return components, data, pkgs, blockers


def _builtin_inspect(ctx):
    p = ctx.item.provider
    details = []
    blocked = []
    status = "ready"
    if p not in PROVIDERS:
        raise Problem("Unknown setup provider: " + p)
    if p in ("paru", "browser") and not packages.arch():
        return Observation(
            id=ctx.id, status="unsupported", summary="This recipe requires Arch/pacman."
        )
    if p == "maintenance":
        if not any(c.enabled for c in ctx.settings.checks.values()):
            return Observation(
                id=ctx.id,
                status="unsupported",
                summary="No health checks enabled; no collector required.",
            )
        details = [
            str(path) + " needs generation"
            for path, content in units.expected().items()
            if not path.is_file() or path.read_text() != content
        ]
        blocked = [
            str(path) + " is not a managed unit; inspect ownership"
            for path in units.expected()
            if path.is_symlink()
            or path.exists()
            and not path.read_text().startswith("# Managed by cq_maintenance setup.\n")
        ]
        details += timer_issues(ctx, ["cq-maintenance.timer"])
    elif p == "paru":
        if not packages.paru_ok(ctx):
            details.append(
                "Paru is missing or cannot start. Rebuild without using the broken helper."
            )
    elif p == "browser":
        details, blocked = browser.inspect(ctx)
        if not packages.installed(ctx, "gopass-jsonapi-git") or not shutil.which(
            "gopass-jsonapi"
        ):
            details.insert(0, "Install gopass-jsonapi-git")
        if not shutil.which("gopass"):
            details.append("Install gopass")
        if not shutil.which("gpg"):
            details.append("Install gnupg")
    elif p == "mail":
        components, data, pkgs, blocked = mail_info(ctx)
        if not components:
            return Observation(
                id=ctx.id,
                status="unsupported",
                summary="No enabled mail/contact checks require timers.",
            )
        if pkgs:
            details.append(
                "Install mail prerequisites: " + ", ".join(sorted(set(pkgs)))
            )
        details += data.get("changed", [])
        root = Path.home() / ".config/mutt/systemd"
        for component in components:
            for suffix in ("service", "timer"):
                path = units.directory() / f"cq-{component}.{suffix}"
                if (
                    not path.is_symlink()
                    or path.resolve() != (root / path.name).resolve()
                    or not path.exists()
                ):
                    details.append("Missing/wrong mail unit link: " + str(path))
                    if path.exists() or path.is_symlink():
                        blocked.append(
                            "Foreign mail unit exists; inspect ownership: " + str(path)
                        )
        details += timer_issues(
            ctx, ["cq-" + component + ".timer" for component in components]
        )
    status = "blocked" if blocked else "required" if details else "ready"
    return Observation(
        id=ctx.id,
        status=status,
        summary="Ready"
        if status == "ready"
        else "Setup blocked"
        if blocked
        else str(len(details)) + " setup conditions need attention",
        details=blocked + details,
    )


def _builtin_plan(ctx, action):
    if (
        action not in ("apply", "rebuild")
        or action == "rebuild"
        and ctx.item.provider != "paru"
    ):
        raise Problem("This recipe does not support action " + action)
    obs = _builtin_inspect(ctx)
    if obs.status in ("unsupported", "disabled"):
        return [], [obs.summary], []
    if obs.status == "blocked":
        return [], obs.details, []
    if obs.status == "ready" and action != "rebuild":
        return [], [], []
    p = ctx.item.provider
    if p == "paru":
        return packages.paru_steps(ctx, force=action == "rebuild"), [], obs.details
    if p == "maintenance":
        return (
            [
                Step(
                    id=ctx.id,
                    kind="maintenance",
                    title="Generate managed monitor units and enable/start its timer",
                )
            ],
            [],
            obs.details,
        )
    if p == "browser":
        pre = packages.pacman_step(ctx, ["gopass", "gnupg"]) + packages.aur_steps(
            ctx, ["gopass-jsonapi-git"]
        )
        return (
            pre
            + [
                Step(
                    id=ctx.id,
                    kind="browser",
                    title="Configure selected browser native hosts, environment and gopass store root",
                    requires=[x.id for x in pre],
                )
            ],
            [],
            obs.details,
        )
    components, data, pkgs, blocked = mail_info(ctx)
    if pkgs and not packages.arch():
        return (
            [],
            ["Missing mail packages require manual installation on this platform."],
            [],
        )
    pre = packages.pacman_step(ctx, pkgs) if pkgs else []
    return (
        pre
        + [
            Step(
                id=ctx.id,
                kind="mail",
                title="Render/link local mail configuration; enable only "
                + ", ".join(components)
                + " timers",
                requires=[x.id for x in pre],
                options={"components": components},
            )
        ],
        blocked,
        obs.details,
    )


def _builtin_watched(ctx):
    if ctx.item.provider == "browser":
        return browser.watched(ctx)
    if ctx.item.provider == "maintenance":
        return list(units.expected())
    if ctx.item.provider == "mail":
        return [Path.home() / ".config/mutt/settings.json"]
    return []


def _builtin_apply(ctx, step):
    from ..util import require

    if step.kind in ("pacman", "aur", "paru"):
        return packages.apply(ctx, step)
    if step.kind == "browser":
        return browser.apply(ctx)
    if step.kind == "maintenance":
        from .core import replace_file

        for path, content in units.expected().items():
            replace_file(path, content, 0o600, ctx)
        return require(
            ctx.run(
                [Path.home() / ".local/bin/cq_maintenance", "setup"],
                foreground=True,
                timeout=60,
            )
        )
    if step.kind == "mail":
        require(
            ctx.run(
                [Path.home() / ".local/bin/cq_mailctl", "setup"],
                foreground=True,
                timeout=120,
            )
        )
        require(
            ctx.run(
                [
                    "systemctl",
                    "--user",
                    "enable",
                    "--now",
                    *["cq-" + c + ".timer" for c in step.options["components"]],
                ],
                foreground=True,
                timeout=60,
            )
        )


class BuiltinProvider:
    """Provider contract: inspect, plan, watched and apply (followed by inspect verification)."""

    inspect = staticmethod(_builtin_inspect)
    plan = staticmethod(_builtin_plan)
    watched = staticmethod(_builtin_watched)
    apply = staticmethod(_builtin_apply)


PROVIDERS = {
    name: BuiltinProvider() for name in ("maintenance", "mail", "paru", "browser")
}


def get(name):
    try:
        return PROVIDERS[name]
    except KeyError:
        raise Problem("Unknown setup provider: " + name) from None


# Independent providers can register the same four hooks without adding branches.
from . import taskwarrior

PROVIDERS["taskwarrior"] = taskwarrior
