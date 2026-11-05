"""Single source of truth for the existing monitoring unit generator."""

import os
from ..config import config_path, xdg


def directory():
    return xdg("config") / "systemd/user"


def expected():
    files = {
        "cq-maintenance.service": "# Managed by cq_maintenance setup.\n[Unit]\nDescription=Collect maintenance observations (no repairs)\n\n[Service]\nType=oneshot\nExecStart=%h/.local/bin/cq_maintenance check --due --quiet\nEnvironment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin\nTimeoutStartSec=5min\nUMask=0077\n",
        "cq-maintenance.timer": "# Managed by cq_maintenance setup.\n[Unit]\nDescription=Check maintenance status every minute\n\n[Timer]\nOnStartupSec=30s\nOnUnitInactiveSec=60s\nUnit=cq-maintenance.service\n\n[Install]\nWantedBy=timers.target\n",
    }
    if os.environ.get("CQ_MAINTENANCE_CONFIG") or os.environ.get("CQ_CONFIG_DIR"):
        selected = (
            str(config_path().resolve())
            .replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("%", "%%")
        )
        files["cq-maintenance.service"] = files["cq-maintenance.service"].replace(
            "[Service]",
            '[Service]\nEnvironment="CQ_MAINTENANCE_CONFIG=' + selected + '"',
        )
    return {directory() / name: content for name, content in files.items()}


def bootstrap_hint(settings):
    if not any(c.enabled for c in settings.checks.values()):
        return None
    if any(not p.is_file() for p in expected()):
        return "Monitoring setup required: generated units are missing. Open Setup → maintenance."
    timer = directory() / "cq-maintenance.timer"
    link = directory() / "timers.target.wants/cq-maintenance.timer"
    if not link.is_symlink() or link.resolve() != timer.resolve():
        return (
            "Monitoring setup required: timer is not enabled. Open Setup → maintenance."
        )
    return None
