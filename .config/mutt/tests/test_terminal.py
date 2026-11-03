"""Exercise the actual NeoMutt/fzf event loop using disposable mail only."""
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import termios
import time
import unittest

import test_mail
from mailcore import ROOT, helper_path


class TerminalIntegration(unittest.TestCase):
    def setUp(self):
        self.fixture = test_mail.MailFixture()
        self.fixture.setUp()
        self.system = self.fixture.system
        self.fixture.message('first', sender='Alice <alice@example.org>')
        self.fixture.message('second', sender='Bob <bob@example.org>')
        self.system.index()
        config = self.fixture.base / 'ui.muttrc'
        config.write_text(f'''source {ROOT}/shared-muttrc
set folder = "{self.system.mail_root}"
set spool_file = "notmuch://{self.system.database}?query=tag:inbox"
set from = "test@example.org"
set sendmail = "/bin/false"
set editor = "/bin/true"
set print_command = "{helper_path()} pdf"
set print = yes
set abort_unmodified = no
set trash = "+.Trash"
set nm_config_file = "{self.system.notmuch_config}"
set nm_default_url = "notmuch://{self.system.database}"
source {self.fixture.base}/bindings.muttrc
''')
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 36, 140, 0, 0))
                os.environ.update(TERM='xterm-256color', LC_ALL='C.UTF-8',
                                  CQ_MAIL_CONFIG=str(self.fixture.base / 'settings.json'))
                os.execvp('neomutt', ['neomutt', '-n', '-F', str(config), '-f',
                                     f'notmuch://{self.system.database}?query=tag:inbox'])
            except BaseException:
                os._exit(1)
        self.initial = self.receive(0.8)

    def receive(self, seconds):
        result = b''
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            readable, _, _ = select.select([self.fd], [], [], 0.1)
            if readable:
                try:
                    result += os.read(self.fd, 65536)
                except OSError:
                    break
        return result

    def send(self, keys, seconds=0.8):
        os.write(self.fd, keys)
        return self.receive(seconds)

    def tearDown(self):
        try:
            os.kill(self.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        os.waitpid(self.pid, 0)
        os.close(self.fd)
        self.fixture.tearDown()

    def test_palette_launches_reply_and_cancel_is_inert(self):
        self.assertIn(b'Test message', self.initial)
        popup = self.send(b'\x1bOP', 1.0)
        self.assertIn(b'action >', popup)
        self.send(b'\x1b', 0.5)
        self.assertEqual(self.fixture.count('tag:inbox'), 2)
        self.send(b'\x1bOP', 1.0)
        composed = self.send(b'Reply to sender\r', 0.2)
        deadline = time.monotonic() + 5
        while b'Compose' not in composed and time.monotonic() < deadline:
            composed += self.receive(0.2)
        self.assertIn(b'Compose', composed)
        self.assertTrue(b'alice@example.org' in composed or b'bob@example.org' in composed,
                        'Reply did not select a message sender')

    def test_filing_selected_messages_and_restoring_confirmations(self):
        self.send(b'T.\r', 0.3)
        result = self.send(b'Ma', 2.0)
        self.assertNotIn(b'Compose', result)
        self.assertEqual(self.fixture.count('tag:inbox'), 0)
        self.assertEqual(self.fixture.count('folder:.Archive'), 2)
        self.assertEqual(self.fixture.count('tag:trash'), 0)
        option = self.send(b':set ?delete\r', 0.4)
        self.assertIn(b'ask-yes', option)

    def test_plain_sync_keeps_its_prompt_without_queued_shell_text(self):
        self.send(b'D', 0.3)
        prompt = self.send(b'S', 0.5)
        self.assertTrue(b'Purge' in prompt or b'deleted' in prompt)
        cancelled = self.send(b'n', 0.5)
        self.assertNotIn(b'Compose', cancelled)
        self.assertNotIn(b'cq_mailctl', cancelled)

    def test_folder_picker_handles_spaces_and_unicode(self):
        picker = self.send(b'g ', 1.0)
        self.assertIn(b'folder >', picker)
        opened = self.send(b'With spaces\r', 1.0)
        self.assertIn('With spaces.æøå'.encode(), opened)
        self.assertNotIn(b'Unknown', opened)

    def test_pdf_export_from_neomutts_decoded_print_stream(self):
        self.send(b'p', 1.4)
        exported = list((self.fixture.base / 'attachments/Emails').glob('*.pdf'))
        self.assertEqual(len(exported), 1)
        text = subprocess.run(['pdftotext', str(exported[0]), '-'], capture_output=True,
                              text=True, check=True).stdout
        self.assertIn('æøå', text)
        self.assertIn('Norwegian text', text)
