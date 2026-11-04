"""Machine-local setup. Never transports mail, decrypts credentials or enables timers."""
from __future__ import annotations

import contextlib
import importlib.util
import os
from pathlib import Path
import subprocess

from mailcore import ROOT, MailError

TIMERS = ('cq-mail.timer', 'cq-contacts.timer')
UNITS = tuple(f'cq-{component}.{kind}' for component in ('mail', 'contacts') for kind in ('service', 'timer'))


def manager(*arguments, check=True):
    result = subprocess.run(['systemctl', '--user', *arguments], capture_output=True, text=True, timeout=30)
    if check and result.returncode:
        raise MailError(f"systemctl {' '.join(arguments)} failed; check the user systemd session")
    return result


def render_local():
    spec = importlib.util.spec_from_file_location('mail_config_builder', ROOT / 'build-config.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.ROOT = ROOT
    module.render()


def inspect_setup(system):
    """Compute drift without rendering files, creating dirs or changing timers."""
    spec = importlib.util.spec_from_file_location('mail_expected_builder', ROOT / 'build-config.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.ROOT = ROOT
    expected = module.render(write=False)
    changed = []
    for path, (content, mode) in expected.items():
        try:
            if path.is_symlink() or path.read_text() != content or path.stat().st_mode & 0o777 != mode:
                changed.append(str(path))
        except (OSError, UnicodeError):
            changed.append(str(path))
    missing = [label for label, ok in system.prerequisite_checks() if not ok]
    return {'needs_setup': bool(changed or missing), 'changed': changed, 'missing_prerequisites': missing}


def user_units():
    base = os.environ.get('XDG_CONFIG_HOME', '')
    return (Path(base) if base and Path(base).is_absolute() else Path.home() / '.config') / 'systemd/user'


def setup_machine(system):
    if system.scheduled:
        raise MailError('Setup must run interactively, not as a scheduled sync job')
    missing = [label for label, ok in system.prerequisite_checks() if not ok]
    if missing:
        raise MailError('Missing prerequisites: ' + ', '.join(missing) + '. Install/configure them, then retry setup.')
    manager('show-environment')
    with system.lock('setup'):
        # Reject unrelated units before stopping timers or writing generated files.
        for unit in UNITS:
            path = user_units() / unit
            expected = ROOT / 'systemd' / unit
            if (path.exists() or path.is_symlink()) and not (path.is_symlink() and path.resolve() == expected.resolve()):
                raise MailError(f'Refusing to replace unrelated user unit: {path}')
        active = []
        for unit in TIMERS:
            result = manager('is-active', unit, check=False)
            if result.returncode not in (0, 3, 4):
                raise MailError(f'Cannot determine timer activity: {unit}')
            if result.stdout.strip() in ('active', 'activating'):
                active.append(unit)
        try:
            if active:
                manager('stop', *active)
            with contextlib.ExitStack() as locks:
                for component in ('mail', 'contacts'):
                    locks.enter_context(system.lock(component))
                # A service can still be starting after timers stop, before it takes its lock.
                for component in ('mail', 'contacts'):
                    result = manager('show', f'cq-{component}.service', '--property=ActiveState', '--value')
                    if result.stdout.strip() not in ('', 'inactive', 'failed'):
                        raise MailError(f'{component} service is busy; retry setup when it finishes')
                render_local()
                missing_links = [str(ROOT / 'systemd' / unit) for unit in UNITS if not (user_units() / unit).is_symlink()]
                if missing_links:
                    manager('link', *missing_links)
                manager('daemon-reload')
        finally:
            # Setup never enables/disables a unit. Restore only previously running timers.
            if active:
                manager('start', *active)
