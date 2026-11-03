#!/usr/bin/env python3
"""Move cq_mailctl into ~/.local/bin and regenerate its mail configuration."""
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def main():
    source = ROOT / 'cq_mailctl'
    destination = Path.home() / '.local/bin/cq_mailctl'
    if not source.exists() and destination.is_file():
        subprocess.run([str(destination), 'render'], check=True)
        print(f'Already installed at {destination}')
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        backup = ROOT / 'backups' / ('cq_mailctl-bin-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(destination, backup)
    descriptor, temporary = tempfile.mkstemp(prefix='.cq_mailctl-', dir=destination.parent)
    try:
        with os.fdopen(descriptor, 'wb') as stream:
            stream.write(source.read_bytes())
            os.fchmod(stream.fileno(), 0o755)
        Path(temporary).replace(destination)
    finally:
        Path(temporary).unlink(missing_ok=True)
    # Render through the installed executable to verify module imports from its new location.
    subprocess.run([str(destination), 'render'], check=True)
    mailcap = ROOT / 'mailcap'
    mailcap.write_text(mailcap.read_text().replace(str(source), str(destination)))
    source.unlink()
    result = subprocess.run(['systemctl', '--user', 'daemon-reload'], capture_output=True)
    print(f'Installed {destination}; updated generated configs and mailcap.')
    if result.returncode:
        print('User systemd reload unavailable; run systemctl --user daemon-reload in your session.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f'cq_mailctl installation failed: {error}')
