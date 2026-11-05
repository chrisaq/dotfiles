"""Native messaging configuration. Never starts the password listener or decrypts."""

from pathlib import Path
import configparser, json, re, shlex, tempfile
from ..config import xdg
from ..util import Problem, require

HOST = "com.justwatch.gopass.json"


def paths(ctx):
    wrapper = Path(
        ctx.item.options.get("wrapper", str(xdg("config") / "gopass/gopass_wrapper.sh"))
    ).expanduser()
    locations = {
        "firefox": Path.home() / ".mozilla/native-messaging-hosts",
        "chrome": xdg("config") / "google-chrome/NativeMessagingHosts",
        "chromium": xdg("config") / "chromium/NativeMessagingHosts",
        "brave": xdg("config") / "BraveSoftware/Brave-Browser/NativeMessagingHosts",
        "vivaldi": xdg("config") / "vivaldi/NativeMessagingHosts",
    }
    targets = ctx.item.options.get("browsers", ["firefox"])
    if not targets or any(name not in locations for name in targets):
        raise Problem("Select supported browser targets: " + ", ".join(locations))
    return wrapper, [(name, locations[name] / HOST) for name in dict.fromkeys(targets)]


def environment(ctx):
    return {
        key: str(Path(ctx.item.options.get(option, default)).expanduser().absolute())
        for key, option, default in [
            ("GNUPGHOME", "gnupghome", "~/.config/gnupg"),
            ("PASSWORD_STORE_DIR", "password_store", "~/Sync/Password-Store"),
        ]
    }


def root_config():
    return xdg("config") / "gopass/config"


def configured_root():
    path = root_config()
    parser = configparser.ConfigParser(interpolation=None)
    if path.exists():
        try:
            parser.read_string(path.read_text())
        except (configparser.Error, UnicodeError):
            raise Problem(
                "Gopass configuration is not a readable INI file; inspect it manually."
            ) from None
    return parser.get("mounts", "path", fallback=None)


def patch_root(text, value):
    lines = text.splitlines(keepends=True)
    section = None
    found = False
    had_section = False
    out = []
    for line in lines:
        if re.match(r"^\s*\[", line):
            if section == "mounts" and not found:
                if out and not out[-1].endswith("\n"):
                    out[-1] += "\n"
                out.append("path = " + value + "\n")
                found = True
            section = line.strip().strip("[]")
            had_section |= section == "mounts"
        if section == "mounts" and re.match(r"^\s*path\s*=", line):
            out.append("path = " + value + "\n")
            found = True
        else:
            out.append(line)
    if not found:
        if out and not out[-1].endswith("\n"):
            out[-1] += "\n"
        if not had_section:
            out.append("\n[mounts]\n")
        out.append("path = " + value + "\n")
    return "".join(out)


def patch_wrapper(text, env):
    if not text.startswith("#!") or "gopass-jsonapi" not in text:
        raise Problem("Unrecognized wrapper; review it manually before adopting it.")
    lines = text.splitlines()
    kept = []
    for line in lines:
        if line in (
            "# BEGIN cq_maintenance environment",
            "# END cq_maintenance environment",
        ):
            continue
        if re.match(r"^\s*export\s+(GNUPGHOME|PASSWORD_STORE_DIR)=", line):
            if (
                ";" in line
                or len(shlex.split(line.strip()[len("export ") :], comments=True)) != 1
            ):
                raise Problem(
                    "Wrapper has a compound environment command; split it before setup."
                )
            continue
        kept.append(line)
    block = (
        ["# BEGIN cq_maintenance environment"]
        + ["export " + key + "=" + shlex.quote(value) for key, value in env.items()]
        + ["# END cq_maintenance environment"]
    )
    return "\n".join(kept[:1] + block + kept[1:]) + "\n"


def inspect(ctx):
    env = environment(ctx)
    wrapper, targets = paths(ctx)
    details = []
    blockers = []
    for key, value in env.items():
        if not Path(value).is_dir():
            blockers.append(
                key
                + " directory missing: "
                + value
                + "; restore your key/store configuration first."
            )
    if configured_root() != env["PASSWORD_STORE_DIR"]:
        details.append(
            "Gopass mounts.path needs correction to " + env["PASSWORD_STORE_DIR"]
        )
    if wrapper.is_symlink():
        blockers.append(
            "Wrapper is a symlink; resolve ownership before setup: " + str(wrapper)
        )
    elif not wrapper.exists():
        details.append("Create native-messaging wrapper: " + str(wrapper))
    else:
        expected = patch_wrapper(wrapper.read_text(), env)
        if expected != wrapper.read_text() or wrapper.stat().st_mode & 0o777 != 0o700:
            details.append("Update wrapper environment/permissions: " + str(wrapper))
    for name, path in targets:
        if path.is_symlink():
            blockers.append("Manifest is a symlink; resolve ownership: " + str(path))
            continue
        if not path.exists():
            details.append(
                "Create " + name + " native-messaging manifest: " + str(path)
            )
            continue
        try:
            manifest = json.loads(path.read_text())
        except (ValueError, UnicodeError):
            blockers.append("Unreadable manifest: " + str(path))
            continue
        if (
            manifest.get("name") != "com.justwatch.gopass"
            or manifest.get("type") != "stdio"
        ):
            blockers.append("Unrecognized manifest: " + str(path))
            continue
        if not manifest.get(
            "allowed_extensions" if name == "firefox" else "allowed_origins"
        ):
            blockers.append(
                "Manifest has no allowed extension identifiers: " + str(path)
            )
        if manifest.get("path") != str(wrapper):
            details.append("Correct manifest wrapper target: " + str(path))
    if root_config().is_symlink():
        blockers.append("Gopass config is a symlink; resolve ownership before setup.")
    return details, blockers


def watched(ctx):
    wrapper, targets = paths(ctx)
    return [root_config(), wrapper, *[p for _, p in targets]]


def apply(ctx):
    from .core import replace_file

    _, blockers = inspect(ctx)
    if blockers:
        raise Problem("; ".join(blockers))
    env = environment(ctx)
    wrapper, targets = paths(ctx)
    generated = {}
    generated_wrapper = None
    # Only generate missing files; existing customizations and allowlists survive.
    if not wrapper.exists() or any(not p.exists() for _, p in targets):
        with tempfile.TemporaryDirectory(prefix="cq-native-host-") as name:
            stage = Path(name)
            for browser, path in targets:
                folder = stage / browser
                folder.mkdir()
                require(
                    ctx.run(
                        [
                            "gopass-jsonapi",
                            "configure",
                            "--browser",
                            "firefox" if browser == "firefox" else "chrome",
                            "--path",
                            str(folder),
                            "--manifest-path",
                            str(folder),
                        ],
                        timeout=30,
                    )
                )
                candidate = folder / "gopass_wrapper.sh"
                manifest = folder / HOST
                if not candidate.is_file() or not manifest.is_file():
                    raise Problem(
                        "Upstream native-host generator did not produce expected files."
                    )
                generated_wrapper = candidate.read_text()
                generated[path] = json.loads(manifest.read_text())
    text = wrapper.read_text() if wrapper.exists() else generated_wrapper
    replacement = patch_wrapper(text, env)
    # Syntax validation never executes the wrapper.
    require(ctx.run(["sh", "-n"], input=replacement, timeout=5))
    root = root_config()
    new_root = patch_root(
        root.read_text() if root.exists() else "", env["PASSWORD_STORE_DIR"]
    )
    replace_file(root, new_root, 0o600, ctx)
    replace_file(wrapper, replacement, 0o700, ctx)
    for name, path in targets:
        data = json.loads(path.read_text()) if path.exists() else generated[path]
        if data.get("name") != "com.justwatch.gopass" or data.get("type") != "stdio":
            raise Problem("Unexpected generated native-host manifest.")
        data["path"] = str(wrapper)
        replace_file(path, json.dumps(data, indent=4) + "\n", 0o600, ctx)
