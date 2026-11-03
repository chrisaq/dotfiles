"""Storage resolution, shared locks, and migration preservation on disposable mail."""
import configparser
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from mailcore import ROOT, MailSystem, MailError, load_settings, ensure_runtime
import test_mail


class XDGPaths(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cq-mail-xdg-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.config = self.base / 'settings.json'
        self.config.write_text((ROOT / 'settings.example.json').read_text())
        self.environment = patch.dict(os.environ, {'CQ_MAIL_CONFIG':str(self.config)}, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def test_default_empty_relative_and_absolute_bases(self):
        defaults = {'data':'.local/share','state':'.local/state','cache':'.cache'}
        for value in (None, '', 'relative/path', str(self.base)):
            with self.subTest(value=value):
                for key in defaults:
                    variable = 'XDG_' + key.upper() + '_HOME'
                    if value is None:
                        os.environ.pop(variable, None)
                    else:
                        os.environ[variable] = value
                settings = load_settings()
                for key, default in defaults.items():
                    expected = self.base if value == str(self.base) else Path.home() / default
                    self.assertEqual(Path(settings[key]), expected / 'cq-mail')

    def test_settings_override_and_child_environment_keep_resolved_roots(self):
        settings = json.loads(self.config.read_text())
        settings.update({key:str(self.base / key) for key in ('data','state','cache','runtime')})
        self.config.write_text(json.dumps(settings))
        parent = MailSystem()
        child_env = parent.environment()
        self.assertEqual(child_env['XDG_CONFIG_HOME'], str(parent.integrations))
        with patch.dict(os.environ, child_env, clear=True):
            os.environ['CQ_MAIL_SCHEDULED'] = '1'
            child = MailSystem()
        for key in ('data','state','cache','runtime','database'):
            self.assertEqual(getattr(parent,key), getattr(child,key))
        with parent.lock():
            with self.assertRaises(MailError):
                with child.lock():
                    self.fail('Scheduled and manual locks diverged')

    def test_runtime_selection_fallback_and_private_directory(self):
        runtime = self.base / 'session'
        runtime.mkdir(mode=0o700)
        os.environ['XDG_RUNTIME_DIR'] = str(runtime)
        self.assertEqual(Path(load_settings()['runtime']), runtime / 'cq-mail')
        with patch('mailcore.private_directory', return_value=False):
            for value in ('', 'relative', str(self.base / 'missing')):
                os.environ['XDG_RUNTIME_DIR'] = value
                self.assertEqual(load_settings()['runtime'], f'/tmp/cq-mail-{os.getuid()}')
        unsafe = self.base / 'unsafe'
        unsafe.mkdir(mode=0o755)
        with self.assertRaises(MailError):
            ensure_runtime(unsafe)
        link = self.base / 'link'
        link.symlink_to(runtime)
        with self.assertRaises(MailError):
            ensure_runtime(link)
        safe = self.base / 'private'
        ensure_runtime(safe)
        self.assertEqual(safe.stat().st_mode & 0o777, 0o700)


class MigrationPreservation(unittest.TestCase):
    setUp = test_mail.MailFixture.setUp
    tearDown = test_mail.MailFixture.tearDown
    message = test_mail.MailFixture.message
    mkdir = test_mail.MailFixture.mkdir
    count = test_mail.MailFixture.count


def test_copy_preserves_custom_tags_and_bootstrap(self):
    self.message('migration')
    self.system.index()
    self.system.nm('tag', '+project/precious', '--', '*')
    before = self.system.nm('dump', '--include=tags').stdout
    destination = self.base / 'migrated'
    shutil.copytree(self.system.data, destination)
    new_state = self.base / 'migrated-state'
    shutil.copytree(self.system.state, new_state)
    config = configparser.ConfigParser()
    config.read(self.system.notmuch_config)
    config['database']['path'] = str(destination / 'notmuch')
    with self.system.notmuch_config.open('w') as stream:
        config.write(stream)
    self.system.data = destination
    self.system.database = destination / 'notmuch'
    self.system.state = new_state
    self.assertEqual(self.system.nm('dump', '--include=tags').stdout, before)
    self.system.index()
    self.assertEqual(self.count('tag:project/precious'), 1)
    self.assertEqual(self.count('tag:history-pending'), 1)


MigrationPreservation.test_copy_preserves_custom_tags_and_bootstrap = test_copy_preserves_custom_tags_and_bootstrap
