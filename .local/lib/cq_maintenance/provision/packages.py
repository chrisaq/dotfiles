"""User-reviewed package operations, also usable without a working AUR helper."""

from pathlib import Path
import os, re, shutil, tempfile
from ..util import Problem, require, cache_dir
from .model import Step


def arch():
    return bool(shutil.which("pacman"))


def installed(ctx, name):
    return ctx.run(["pacman", "-Q", name]).returncode == 0


def missing(ctx, names):
    return sorted(n for n in set(names) if not installed(ctx, n))


def paru_ok(ctx):
    if not shutil.which("paru"):
        return False
    try:
        return ctx.run(["paru", "--version"], timeout=5).returncode == 0
    except Problem:
        return False


def validate(names):
    if any(not re.fullmatch(r"[A-Za-z0-9@._+][A-Za-z0-9@._+:-]*", n) for n in names):
        raise Problem("Invalid package name")


def pacman_step(ctx, names):
    names = missing(ctx, names)
    return (
        [
            Step(
                id="packages:" + ",".join(names),
                kind="pacman",
                title="Install repository packages: " + ", ".join(names),
                options={"packages": names},
            )
        ]
        if names
        else []
    )


def paru_steps(ctx, force=False):
    if paru_ok(ctx) and not force:
        return []
    prerequisites = pacman_step(ctx, ["base-devel", "git"])
    return prerequisites + [
        Step(
            id="paru",
            kind="paru",
            title="Build/install stable paru from its reviewed AUR PKGBUILD (without using paru)",
            requires=[s.id for s in prerequisites],
        )
    ]


def aur_steps(ctx, names):
    names = missing(ctx, names)
    if not names:
        return []
    prerequisites = paru_steps(ctx)
    return prerequisites + [
        Step(
            id="aur:" + ",".join(names),
            kind="aur",
            title="Install AUR packages: " + ", ".join(names),
            requires=[s.id for s in prerequisites],
            options={"packages": names},
        )
    ]


def apply(ctx, step):
    if step.kind == "pacman":
        names = missing(ctx, step.options["packages"])
        validate(names)
        if names:
            result = ctx.run(
                ["sudo", "pacman", "-S", "--needed", "--", *names],
                foreground=True,
                timeout=7200,
            )
            if result.returncode:
                raise Problem(
                    "Package installation failed. If repository metadata/ABI is stale, use the separately reviewed Arch upgrade, then re-plan. Do not run pacman -Sy alone."
                )
    elif step.kind == "aur":
        names = missing(ctx, step.options["packages"])
        validate(names)
        if names:
            if not paru_ok(ctx):
                raise Problem("Paru is not working; re-plan its prerequisite repair.")
            require(
                ctx.run(
                    ["paru", "-S", "--needed", "--", *names],
                    foreground=True,
                    timeout=7200,
                )
            )
    elif step.kind == "paru":
        if os.geteuid() == 0:
            raise Problem("Build paru as a normal user, never as root.")
        root = cache_dir() / "setup/builds"
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        build = Path(tempfile.mkdtemp(prefix="paru-", dir=root))
        require(
            ctx.run(
                [
                    "git",
                    "clone",
                    "--",
                    "https://aur.archlinux.org/paru.git",
                    str(build / "source"),
                ],
                foreground=True,
                timeout=120,
            )
        )
        source = build / "source"
        revision = require(
            ctx.run(["git", "rev-parse", "HEAD"], cwd=source)
        ).stdout.strip()
        recipe = source / "PKGBUILD"
        if recipe.is_symlink() or not recipe.is_file():
            raise Problem("Unexpected AUR PKGBUILD path")
        before = recipe.read_bytes()
        ctx.display("AUR source revision " + revision + "\n\n" + before.decode())
        if not ctx.confirm("Build this reviewed paru PKGBUILD as your normal user?"):
            raise Problem("Paru build cancelled; checkout retained at " + str(source))
        if (
            require(
                ctx.run(["git", "status", "--porcelain"], cwd=source)
            ).stdout.strip()
            or recipe.read_bytes() != before
            or require(ctx.run(["git", "rev-parse", "HEAD"], cwd=source)).stdout.strip()
            != revision
        ):
            raise Problem("Build source changed after review; re-plan.")
        require(ctx.run(["makepkg", "-si"], cwd=source, foreground=True, timeout=7200))
        if not paru_ok(ctx):
            raise Problem(
                "Paru still cannot start after rebuilding; inspect the build and installed libalpm versions."
            )
