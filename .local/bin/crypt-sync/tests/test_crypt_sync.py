#!/usr/bin/env python3
"""Exercise crypt-sync using disposable homes and keyrings only."""

import os
from pathlib import Path
import shutil
import signal
import stat
import subprocess
import tempfile
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'crypt-sync.sh'
REAL_GPG = shutil.which('gpg')
MOCK_GPG = r'''#!/usr/bin/env python3
import os
from pathlib import Path
import signal
import sys

args = sys.argv[1:]
output = Path(args[args.index('--output') + 1])
source = Path(args[-1])
mode = os.environ.get('TEST_GPG_MODE', 'copy')
if mode == 'wait':
    output.write_bytes(b'partial output')
    Path(os.environ['TEST_READY']).touch()
    signal.pause()
    sys.exit(1)
if mode == 'fail' or source.name == 'fail.gpg':
    output.write_bytes(b'partial output')
    sys.exit(1)
data = source.read_bytes()
if '--decrypt' in args:
    if not data.startswith(b'encrypted:'):
        sys.exit(1)
    output.write_bytes(data[len(b'encrypted:'):])
else:
    output.write_bytes(b'encrypted:' + data)
'''


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='crypt-sync-test-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / 'home with spaces'
        self.bin = self.root / 'bin'
        self.lists = self.bin / 'crypt-sync'
        self.vault = self.home / 'Sync/Password-Store/ConfigFiles'
        self.lists.mkdir(parents=True)
        self.vault.mkdir(parents=True)
        self.env = dict(os.environ, HOME=str(self.home),
                        PASSWORD_STORE_DIR=str(self.home / 'Sync/Password-Store'),
                        XDG_BIN_HOME=str(self.bin), XDG_STATE_HOME=str(self.root / 'state'),
                        PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        self.install_command('gpg', MOCK_GPG)
        self.set_list('example.gpg:configs/example config\n')

    def install_command(self, name, contents):
        command = self.bin / name
        command.write_text(contents)
        command.chmod(0o700)

    def set_list(self, contents):
        (self.lists / 'crypt-sync-list.txt').write_text(contents)

    def write(self, path, content, newer=False):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        path.chmod(0o644)
        timestamp = 1_700_000_000_123_456_789 + (10_000_000_000 if newer else 0)
        os.utime(path, ns=(timestamp, timestamp))
        return path

    def paths(self, direction):
        local = self.home / 'configs/example config'
        encrypted = self.vault / 'example.gpg'
        return (encrypted, local) if direction == 'decrypt' else (local, encrypted)

    def prepare(self, direction, existing):
        source, destination = self.paths(direction)
        data = b'encrypted:new contents' if direction == 'decrypt' else b'new contents'
        self.write(source, data, newer=True)
        if existing:
            self.write(destination, b'old contents')
        return source, destination

    def snapshot(self, path):
        info = path.stat()
        return path.read_bytes(), info.st_mtime_ns, stat.S_IMODE(info.st_mode), info.st_ino

    def run_sync(self):
        return subprocess.run(['/bin/bash', str(SCRIPT)], env=self.env,
                              capture_output=True, text=True, timeout=15)

    def assert_no_temporaries(self):
        self.assertEqual(list(self.home.rglob('.crypt-sync.*')), [])

    def test_successful_transfers(self):
        for direction in ('encrypt', 'decrypt'):
            for existing in (False, True):
                with self.subTest(direction=direction, existing=existing):
                    for path in self.paths(direction):
                        path.unlink(missing_ok=True)
                    source, destination = self.prepare(direction, existing)
                    original_source = self.snapshot(source)
                    result = self.run_sync()
                    self.assertEqual(result.returncode, 0, result.stderr)
                    expected = b'new contents' if direction == 'decrypt' else b'encrypted:new contents'
                    self.assertEqual(destination.read_bytes(), expected)
                    self.assertEqual(destination.stat().st_mtime_ns, source.stat().st_mtime_ns)
                    self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o600)
                    self.assertEqual(self.snapshot(source), original_source)
                    self.assert_no_temporaries()
                    unchanged = self.snapshot(destination)
                    self.assertEqual(self.run_sync().returncode, 0)
                    self.assertEqual(self.snapshot(destination), unchanged)

    def test_partial_gpg_failure_preserves_destination(self):
        self.env['TEST_GPG_MODE'] = 'fail'
        for direction in ('encrypt', 'decrypt'):
            for existing in (False, True):
                with self.subTest(direction=direction, existing=existing):
                    for path in self.paths(direction):
                        path.unlink(missing_ok=True)
                    source, destination = self.prepare(direction, existing)
                    before = self.snapshot(destination) if existing else None
                    result = self.run_sync()
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('GPG failed', result.stderr)
                    if existing:
                        self.assertEqual(self.snapshot(destination), before)
                    else:
                        self.assertFalse(destination.exists())
                    self.assert_no_temporaries()

    def test_filesystem_failures_preserve_destination(self):
        for command in ('mkdir', 'mktemp', 'chmod', 'touch', 'mv'):
            with self.subTest(command=command):
                source, destination = self.prepare('decrypt', True)
                before = self.snapshot(destination)
                real_command = shutil.which(command)
                # mkdir must still allow creation of the lock directory.
                wrapper = ('#!/bin/sh\n'
                           'for arg do\n'
                           '  if [ "$arg" = "$TEST_FAIL_DIRECTORY" ]; then exit 1; fi\n'
                           'done\n'
                           f'exec "{real_command}" "$@"\n') if command == 'mkdir' else '#!/bin/sh\nexit 1\n'
                self.env['TEST_FAIL_DIRECTORY'] = str(destination.parent)
                self.install_command(command, wrapper)
                try:
                    result = self.run_sync()
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(self.snapshot(destination), before)
                    self.assert_no_temporaries()
                finally:
                    (self.bin / command).unlink()

    def test_failure_continues_through_other_entries_and_lists(self):
        self.set_list('fail.gpg:failed config\nexample.gpg:configs/example config\n')
        (self.lists / 'crypt-sync-list-local.txt').write_text('other.gpg:other config')
        self.write(self.vault / 'fail.gpg', b'encrypted:failure')
        self.write(self.vault / 'other.gpg', b'encrypted:other')
        self.prepare('decrypt', False)
        result = self.run_sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / 'failed config').exists())
        self.assertEqual((self.home / 'configs/example config').read_bytes(), b'new contents')
        self.assertEqual((self.home / 'other config').read_bytes(), b'other')
        self.assert_no_temporaries()

    def test_successful_skips(self):
        self.set_list('# comment\n\nmissing.gpg:missing\nexample.gpg:configs/example config')
        source, destination = self.paths('decrypt')
        self.write(source, b'encrypted:different content')
        self.write(destination, b'unchanged')
        before = self.snapshot(destination)
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.snapshot(destination), before)
        self.assertFalse((self.home / 'missing').exists())
        self.assertIn('Same date', result.stdout)
        self.assertIn('Missing both', result.stdout)

    def test_malformed_entry_reports_failure_and_continues(self):
        self.set_list('invalid\nexample.gpg:configs/example config\n')
        self.prepare('decrypt', False)
        result = self.run_sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('malformed', result.stderr)
        self.assertTrue((self.home / 'configs/example config').exists())

    def test_nonregular_list_reports_failure_and_continues(self):
        (self.lists / 'crypt-sync-list-directory.txt').mkdir()
        self.prepare('decrypt', False)
        result = self.run_sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Not a regular list', result.stderr)
        self.assertTrue((self.home / 'configs/example config').exists())

    def test_nonregular_paths_are_refused(self):
        for side in ('source', 'destination'):
            for kind in ('symlink', 'broken_symlink', 'directory', 'fifo'):
                with self.subTest(side=side, kind=kind):
                    source, destination = self.prepare('decrypt', True)
                    path = source if side == 'source' else destination
                    path.unlink()
                    target = self.write(self.root / 'symlink target', b'untouched')
                    before = self.snapshot(target)
                    if kind == 'symlink':
                        path.symlink_to(target)
                    elif kind == 'broken_symlink':
                        path.symlink_to(self.root / 'does not exist')
                    elif kind == 'directory':
                        path.mkdir()
                    else:
                        os.mkfifo(path)
                    try:
                        result = self.run_sync()
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn('Refusing', result.stderr)
                        self.assertEqual(self.snapshot(target), before)
                        self.assert_no_temporaries()
                    finally:
                        path.rmdir() if kind == 'directory' else path.unlink()

    def start_waiting_run(self):
        ready = self.root / 'ready'
        ready.unlink(missing_ok=True)
        env = dict(self.env, TEST_GPG_MODE='wait', TEST_READY=str(ready))
        process = subprocess.Popen(['/bin/bash', str(SCRIPT)], env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, start_new_session=True)
        def stop():
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
            process.communicate(timeout=10)
        self.addCleanup(stop)
        deadline = time.monotonic() + 10
        while not ready.exists():
            if process.poll() is not None:
                self.fail(f'Run exited before GPG was ready: {process.communicate()}')
            if time.monotonic() >= deadline:
                self.fail('GPG did not become ready')
            time.sleep(0.02)
        return process

    def test_handled_signals_clean_up_and_release_lock(self):
        for signum in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            with self.subTest(signal=signum):
                source, destination = self.prepare('decrypt', True)
                before = self.snapshot(destination)
                process = self.start_waiting_run()
                self.assertEqual(self.snapshot(destination), before)
                self.assertEqual(len(list(self.home.rglob('.crypt-sync.*'))), 1)
                os.killpg(process.pid, signum)
                process.communicate(timeout=10)
                self.assertEqual(process.returncode, 128 + signum)
                self.assertEqual(self.snapshot(destination), before)
                self.assert_no_temporaries()
                self.assertEqual(self.run_sync().returncode, 0)

    def test_overlapping_run_exits_without_processing_files(self):
        source, destination = self.prepare('decrypt', True)
        before = self.snapshot(destination)
        process = self.start_waiting_run()
        result = self.run_sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('lock', result.stderr)
        self.assertEqual(result.stdout, '')
        self.assertEqual(self.snapshot(destination), before)
        os.killpg(process.pid, signal.SIGTERM)
        process.communicate(timeout=10)
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertTrue((Path(self.env['XDG_STATE_HOME']) / 'crypt-sync/run.lock').is_file())

    def test_lock_directory_failure_stops_before_processing(self):
        self.prepare('decrypt', False)
        blocker = self.root / 'not a directory'
        blocker.write_text('blocked')
        self.env['XDG_STATE_HOME'] = str(blocker)
        result = self.run_sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertFalse(self.paths('decrypt')[1].exists())

    def test_lock_defaults_to_local_state_directory(self):
        self.env.pop('XDG_STATE_HOME')
        self.prepare('decrypt', False)
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        lock = self.home / '.local/state/crypt-sync/run.lock'
        self.assertTrue(lock.is_file())
        self.assertEqual(stat.S_IMODE(lock.stat().st_mode), 0o600)

    @unittest.skipUnless(REAL_GPG, 'GPG is required for the real round trip')
    def test_real_gpg_round_trip(self):
        keyring = self.root / 'gnupg'
        keyring.mkdir(mode=0o700)
        self.env['GNUPGHOME'] = str(keyring)
        def gpg(*args):
            result = subprocess.run([REAL_GPG, '--homedir', str(keyring), '--batch', *args],
                                    env=self.env, capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result
        def stop_agent():
            gpgconf = shutil.which('gpgconf')
            if gpgconf:
                subprocess.run([gpgconf, '--homedir', str(keyring), '--kill', 'gpg-agent'],
                               env=self.env, capture_output=True, timeout=10)
        self.addCleanup(stop_agent)
        gpg('--pinentry-mode', 'loopback', '--passphrase', '', '--quick-generate-key',
            'crypt-sync disposable test key', 'rsa2048', 'encr', '0')
        keys = gpg('--with-colons', '--list-keys').stdout
        fingerprint = next(line.split(':')[9] for line in keys.splitlines()
                           if line.startswith('fpr:'))
        # Production keeps its configured recipient. Substitute only the recipient
        # in this test wrapper so the test never needs the user's private key.
        self.install_command('gpg', f'''#!/usr/bin/env python3
import os
import sys
args = ["{fingerprint}" if arg == "0xAEE3FD309AFCC09E" else arg for arg in sys.argv[1:]]
os.execv({REAL_GPG!r}, [{REAL_GPG!r}, '--batch', '--pinentry-mode', 'loopback', '--passphrase', '', *args])
''')
        source, encrypted = self.prepare('encrypt', False)
        original = source.read_bytes()
        timestamp = source.stat().st_mtime_ns
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(encrypted.read_bytes().startswith(b'-----BEGIN PGP MESSAGE-----'))
        source.unlink()
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(source.read_bytes(), original)
        self.assertEqual(source.stat().st_mtime_ns, timestamp)
        self.assertEqual(stat.S_IMODE(source.stat().st_mode), 0o600)
        self.assert_no_temporaries()


if __name__ == '__main__':
    unittest.main(verbosity=2)
