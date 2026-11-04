"""Setup on disposable machines, preserving local data and timer choices."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest
from unittest.mock import patch

from mailcore import ROOT, MailSystem, MailError, load_settings
import mailsetup
import test_mail


class MachineSetup(unittest.TestCase):
    setUpFixture = test_mail.MailFixture.setUp
    tearDown = test_mail.MailFixture.tearDown
    mkdir = test_mail.MailFixture.mkdir

    def setUp(self):
        self.setUpFixture()
        self.units = self.base / 'user-units'
        self.units.mkdir()
        shutil.copy2(ROOT / 'build-config.py', self.base / 'build-config.py')
        self.active = {'cq-mail.timer':True, 'cq-contacts.timer':False}
        self.enabled = {'cq-mail.timer':True, 'cq-contacts.timer':False}
        self.calls = []
        self.service_state = 'inactive'
        for target, attribute, value in ((mailsetup, 'ROOT', self.base),
                                         (mailsetup, 'user_units', lambda:self.units),
                                         (mailsetup, 'manager', self.manager),
                                         (self.system, 'prerequisite_checks', lambda:[('tools',True)])):
            patcher = patch.object(target, attribute, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def manager(self, *args, check=True):
        self.calls.append(args)
        result = ''
        code = 0
        if args[0]=='is-active':
            result = 'active' if self.active[args[1]] else 'inactive'
            code = 0 if self.active[args[1]] else 3
        elif args[0] in ('stop','start'):
            for unit in args[1:]: self.active[unit] = args[0]=='start'
        elif args[0]=='show':
            result = self.service_state
        elif args[0]=='link':
            for source in args[1:]: (self.units / Path(source).name).symlink_to(source)
        elif args[0] not in ('show-environment','daemon-reload'):
            self.fail('Unexpected side effect: '+str(args))
        return subprocess.CompletedProcess(args,code,result,'')

    def test_first_setup_and_repeated_setup_are_offline_and_preserve_choices(self):
        before = dict(self.active)
        with patch.object(self.system, 'secret', side_effect=AssertionError('Decryption')), patch.object(self.system, 'nm', side_effect=AssertionError('Index access')), patch.object(self.system, 'run', side_effect=AssertionError('Transport')):
            mailsetup.setup_machine(self.system)
            mailsetup.setup_machine(self.system)
        self.assertEqual(self.active,before)
        self.assertEqual(self.enabled,{'cq-mail.timer':True,'cq-contacts.timer':False})
        self.assertEqual(sum(call[0]=='link' for call in self.calls),1)
        self.assertFalse(self.system.database_exists())
        self.assertFalse((self.system.state/'bootstrap-complete').exists())
        self.assertTrue(all((self.units/name).is_symlink() for name in mailsetup.UNITS))
        service=(self.base/'systemd/cq-mail.service').read_text()
        self.assertIn('CQ_MAIL_CONFIG='+str(self.base/'settings.json'),service)
        self.assertIn('CQ_MAIL_RUNTIME='+str(self.system.runtime),service)

    def test_all_timers_inactive_remain_inactive(self):
        self.active={key:False for key in self.active}
        mailsetup.setup_machine(self.system)
        self.assertFalse(any(self.active.values()))
        self.assertFalse(any(call[0] in ('start','stop') for call in self.calls))

    def test_busy_contacts_restores_timers_without_rendering(self):
        with self.system.lock('contacts'), patch.object(mailsetup,'render_local') as render:
            with self.assertRaisesRegex(MailError,'already running'):
                mailsetup.setup_machine(self.system)
        render.assert_not_called()
        self.assertEqual(self.active,{'cq-mail.timer':True,'cq-contacts.timer':False})

    def test_starting_service_refuses_setup_even_before_it_locks(self):
        self.service_state='activating'
        with patch.object(mailsetup,'render_local') as render:
            with self.assertRaisesRegex(MailError,'busy'):
                mailsetup.setup_machine(self.system)
        render.assert_not_called()
        self.assertTrue(self.active['cq-mail.timer'])

    def test_failed_render_restores_active_timers(self):
        with patch.object(mailsetup,'render_local',side_effect=MailError('render failed')):
            with self.assertRaisesRegex(MailError,'render failed'):
                mailsetup.setup_machine(self.system)
        self.assertEqual(self.active,{'cq-mail.timer':True,'cq-contacts.timer':False})

    def test_missing_prerequisites_and_foreign_units_fail_before_changes(self):
        with patch.object(self.system,'prerequisite_checks',return_value=[('mbsync',False)]):
            with self.assertRaisesRegex(MailError,'mbsync'):
                mailsetup.setup_machine(self.system)
        self.assertEqual(self.calls,[])
        (self.units/'cq-mail.service').write_text('unrelated service')
        with self.assertRaisesRegex(MailError,'unrelated'):
            mailsetup.setup_machine(self.system)
        self.assertFalse(any(call[0]=='stop' for call in self.calls))
        self.assertEqual((self.units/'cq-mail.service').read_text(),'unrelated service')

    def test_prerequisites_do_not_require_mail_index_or_decrypt(self):
        Path(self.system.settings['gnupghome']).mkdir()
        result=subprocess.CompletedProcess([],0,'NeoMutt +notmuch','')
        with patch('mailcore.shutil.which',return_value='/bin/tool'), patch('mailcore.subprocess.run',return_value=result) as run, patch.object(self.system,'secret',side_effect=AssertionError('Decryption')):
            checks=MailSystem.prerequisite_checks(self.system)
        self.assertTrue(all(ok for _,ok in checks),checks)
        self.assertEqual(run.call_args.args[0],['neomutt','-v'])
        self.assertEqual(run.call_count,1)
        self.assertFalse(self.system.database_exists())
        self.system.settings['tls_ca_file']=str(self.base/'missing-ca')
        with patch('mailcore.shutil.which',return_value=None):
            self.assertFalse(dict(MailSystem.prerequisite_checks(self.system))['TLS CA file'])

    def test_scheduled_invocation_is_rejected(self):
        self.system.scheduled=True
        with self.assertRaisesRegex(MailError,'interactively'):
            mailsetup.setup_machine(self.system)
        self.assertEqual(self.calls,[])


class SharedSettings(unittest.TestCase):
    def test_same_settings_render_separate_machine_paths(self):
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            base=Path(directory)
            settings=json.loads((ROOT/'settings.example.json').read_text())
            config=base/'settings.json';config.write_text(json.dumps(settings))
            systems=[]
            import importlib.util
            spec=importlib.util.spec_from_file_location('two_machine_builder',ROOT/'build-config.py')
            builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
            for number in (1,2):
                home=base/f'home-{number}';home.mkdir()
                runtime=base/f'runtime-{number}';runtime.mkdir(mode=0o700)
                environment={'HOME':str(home),'CQ_MAIL_CONFIG':str(config),'XDG_RUNTIME_DIR':str(runtime)}
                with patch.dict(os.environ,environment,clear=True), patch('pathlib.Path.home',return_value=home), patch('mailcore.os.getuid',return_value=1000+number), patch('mailcore.private_directory',side_effect=lambda p:p==runtime):
                    system=MailSystem();systems.append(system)
                    self.assertEqual(system.mail_root,home/'.local/share/mail/example.org')
                    self.assertEqual(system.runtime,runtime/'cq-mail')
                    local_config=home/'.config/mutt';local_config.mkdir(parents=True)
                    executable=home/'.local/bin/cq_mailctl';executable.parent.mkdir(parents=True);executable.write_text('#!/bin/true\n')
                    for name in ('actions.json','rules.json','mailcap.in'):
                        shutil.copy2(ROOT/name,local_config/name)
                    with patch.object(builder,'ROOT',local_config):
                        builder.render()
                    service=(local_config/'systemd/cq-mail.service').read_text()
                    self.assertIn(str(runtime/'cq-mail'),service)
                    self.assertIn(str(home/'.local/share/cq-mail'),service)
                    self.assertIn(str(executable),service)
                    self.assertIn(str(home/'.local/share/cq-mail/notmuch'),(local_config/'integrations/notmuch/config').read_text())
            self.assertNotEqual(systems[0].database,systems[1].database)
            self.assertNotEqual(systems[0].settings['gnupghome'],systems[1].settings['gnupghome'])
            self.assertEqual(systems[0].settings['primary_email'],systems[1].settings['primary_email'])

class SetupDrift(unittest.TestCase):
    setUp = MachineSetup.setUp
    setUpFixture = MachineSetup.setUpFixture
    tearDown = MachineSetup.tearDown
    mkdir = MachineSetup.mkdir
    manager = MachineSetup.manager
    # Exercise the same real isolated renderer as setup, without importing live configs.
    def test_expected_outputs_do_not_write_and_detect_drift(self):
        mailsetup.setup_machine(self.system)
        paths=list(self.base.rglob('*'))
        before={str(p):p.stat().st_mtime_ns for p in paths if p.is_file() and '__pycache__' not in str(p)}
        result=mailsetup.inspect_setup(self.system)
        self.assertFalse(result['needs_setup'],result)
        after={str(p):p.stat().st_mtime_ns for p in self.base.rglob('*') if p.is_file() and '__pycache__' not in str(p)}
        self.assertEqual(before,after)
        target=self.base/'integrations/mbsyncrc';target.write_text('stale config')
        result=mailsetup.inspect_setup(self.system)
        self.assertIn(str(target),result['changed'])
        self.assertEqual(target.read_text(),'stale config')
