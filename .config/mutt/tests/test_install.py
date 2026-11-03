"""Verify relocation without writing to the real ~/.local/bin or user manager."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import shlex
import tempfile
import unittest

from mailcore import ROOT, helper_path


class LauncherInstallation(unittest.TestCase):
    def test_installed_launcher_imports_modules_and_updates_all_callers(self):
        with tempfile.TemporaryDirectory(prefix='cq-mail-install-') as temporary:
            home = Path(temporary)
            config = home / '.config/mutt'
            config.mkdir(parents=True)
            for name in ('cq_mailctl', 'install-cq_mailctl.py', 'build-config.py', 'mailcore.py',
                         'mailcontacts.py', 'mailui.py', 'rules.json', 'mailcap.in'):
                source = ROOT / name
                if name == 'cq_mailctl' and not source.exists():
                    source = helper_path()
                shutil.copy2(source, config / name)
            (config / 'actions.json').write_text((ROOT / 'actions.json').read_text().replace(str(ROOT), str(config)))
            settings = json.loads((ROOT / 'settings.example.json').read_text())
            settings.update(mail_root=str(home / 'mail'), state=str(home / 'state'), data=str(home / 'data'),
                            cache=str(home / 'cache'), runtime=str(home / 'runtime'),
                            password_store=str(home / 'store'), gnupghome=str(home / 'gpg'),
                            attachments=str(home / 'attachments'))
            (config / 'settings.json').write_text(json.dumps(settings))
            (config / 'mailcap').write_text(f'text/html; {config}/cq_mailctl open %s\n')
            fake_bin = home / 'test-bin'
            fake_bin.mkdir()
            systemctl = fake_bin / 'systemctl'
            systemctl.write_text('#!/bin/sh\nexit 0\n')
            systemctl.chmod(0o755)
            # The sandbox cannot download uv dependencies. Exercise the installed
            # shebang using the test interpreter, which already has those dependencies.
            uv = fake_bin / 'uv'
            uv.write_text('#!/bin/sh\n[ \"$1\" = run ] && shift\n[ \"$1\" = --script ] && shift\nexec ' + shlex.quote(sys.executable) + ' \"$@\"\n')
            uv.chmod(0o755)
            environment = dict(os.environ, HOME=str(home), PATH=str(fake_bin) + os.pathsep + os.environ['PATH'])
            environment.pop('CQ_MAIL_CONFIG', None)
            command = ['python3', str(config / 'install-cq_mailctl.py')]
            subprocess.run(command, env=environment, cwd='/tmp', capture_output=True, check=True)
            executable = home / '.local/bin/cq_mailctl'
            self.assertTrue(os.access(executable, os.X_OK))
            self.assertFalse((config / 'cq_mailctl').exists())
            self.assertFalse((config / 'cq_mailctl').is_symlink())
            for header in ('#:usage:', '#:no-args: true', '#:desc:'):
                self.assertIn(header, executable.read_text())
            help_result = subprocess.run([str(executable), '--help'], env=environment,
                                         cwd='/tmp', capture_output=True, text=True, check=True)
            self.assertIn('Managed personal', help_result.stdout)
            for relative in ('bindings.muttrc', 'integration.muttrc', 'integrations/mbsyncrc',
                             'integrations/msmtprc', 'integrations/vdirsyncer/config',
                             'systemd/cq-mail.service', 'systemd/cq-contacts.service',
                             'integrations/notmuch/hooks/post-new', 'mailcap'):
                text = (config / relative).read_text()
                self.assertIn(str(executable), text, relative)
                self.assertNotIn(str(config / 'cq_mailctl'), text, relative)
            subprocess.run(command, env=environment, cwd='/tmp', capture_output=True, check=True)
