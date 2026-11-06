import configparser
from contextlib import redirect_stdout
from email.message import EmailMessage
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from mailcore import ROOT, MailSystem, MailError, MailBusy, MailUnlockRequired
import mailcontacts
import mailui


class MailFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='cq-mail-test-')
        self.base = Path(self.temporary.name)
        settings = json.loads((ROOT / 'settings.example.json').read_text())
        settings.update(mail_root=str(self.base / 'mail'), state=str(self.base / 'state'), data=str(self.base / 'data'),
                        cache=str(self.base / 'cache'), runtime=str(self.base / 'runtime'),
                        attachments=str(self.base / 'attachments'),
                        integrations=str(self.base / 'integrations'),
                        password_store=str(self.base / 'store'), gnupghome=str(self.base / 'gpg'))
        for entry in settings['credentials'].values():
            entry_path = self.base / 'store' / (entry + '.gpg')
            entry_path.parent.mkdir(parents=True, exist_ok=True)
            entry_path.write_text('Test placeholder; never decrypted')
        settings_path = self.base / 'settings.json'
        settings_path.write_text(json.dumps(settings))
        self.env = patch.dict(os.environ, CQ_MAIL_CONFIG=str(settings_path))
        self.env.start()
        self.system = MailSystem()
        notifier = patch.object(self.system, 'notify_unlock', return_value=True)
        self.notify = notifier.start()
        self.addCleanup(notifier.stop)
        status_notify = patch.object(self.system, 'notify_maintenance')
        status_notify.start()
        self.addCleanup(status_notify.stop)
        import importlib.util
        spec = importlib.util.spec_from_file_location('fixture_builder', ROOT / 'build-config.py')
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        for name in ('rules.json', 'actions.json', 'mailcap.in'):
            shutil.copy2(ROOT / name, self.base / name)
        with patch.object(builder, 'ROOT', self.base):
            builder.render()
        for folder in ('', '.Archive', '.Archives.2005', '.Spam', '.Trash', '.Sent', '.Drafts', '.With spaces.æøå'):
            self.mkdir(folder)

    def tearDown(self):
        self.env.stop()
        self.temporary.cleanup()

    def mkdir(self, folder):
        for part in ('cur', 'new', 'tmp'):
            (self.system.mail_root / folder / part).mkdir(parents=True, exist_ok=True)

    def message(self, ident, folder='', sender='Person <hello@example.org>', flags='S', **headers):
        message = EmailMessage()
        message['From'] = sender
        message['To'] = 'Example User <user@example.org>'
        message['Subject'] = 'Test message æøå'
        message['Message-ID'] = f'<{ident}@example.org>'
        message['Date'] = 'Tue, 03 Nov 2026 12:00:00 +0100'
        for key, value in headers.items():
            message[key.replace('_', '-')] = value
        message.set_content('Norwegian text: æøå\n')
        path = self.system.mail_root / folder / 'cur' / f'{ident}:2,{flags}'
        path.write_bytes(message.as_bytes())
        return path

    def count(self, query):
        return int(self.system.nm('count', '--exclude=false', query).stdout)

    def test_bootstrap_preserves_history_and_read_state(self):
        bank = self.message('bank', sender='Bank <notice@dnb.no>')
        self.message('old', '.Archives.2005', sender='Bank <old@dnb.no>')
        self.message('flagged', flags='F')
        self.system.index()
        self.assertTrue(self.system.database_exists())
        self.assertEqual(self.count('tag:history-pending'), 3)
        self.assertEqual(self.count('tag:inbox'), 2)
        self.assertEqual(self.count('tag:category/finance'), 0)
        self.assertEqual(self.count('id:bank@example.org and tag:unread'), 0)
        self.assertEqual(self.count('id:flagged@example.org and tag:unread and tag:flagged'), 1)
        self.assertTrue(bank.exists())
        self.system.apply_history()
        self.assertEqual(self.count('tag:category/finance'), 2)
        self.assertEqual(self.count('tag:history-pending'), 0)
        self.assertEqual(self.count('tag:inbox'), 2)
        self.assertEqual(self.count('id:bank@example.org and tag:unread'), 0)

    def test_new_mail_categories_headers_and_spam(self):
        self.system.index()
        self.message('new', sender='Bank <notice@dnb.no>', flags='')
        self.message('spam', '.Spam', sender='Bank <bad@dnb.no>')
        self.message('list', List_Id='<project.example.org>', List_Unsubscribe='<https://example.org/unsubscribe>')
        self.message('wrong-domain', sender='Imposter <x@dnb.no.attacker.example>')
        self.system.index()
        self.assertEqual(self.count('id:new@example.org and tag:category/finance and tag:inbox and tag:unread'), 1)
        self.assertEqual(self.count('id:spam@example.org and tag:spam'), 1)
        self.assertEqual(self.count('id:spam@example.org and tag:category/finance'), 0)
        self.assertEqual(self.count('id:wrong-domain@example.org and tag:category/finance'), 0)
        self.assertEqual(self.count('id:list@example.org and tag:category/lists and tag:category/newsletters'), 1)
        self.assertEqual(self.count('tag:new'), 0)

    def test_moves_duplicates_and_manual_tags_survive(self):
        first = self.message('move', sender='Bank <notice@dnb.no>')
        self.system.index()
        self.system.apply_history()
        self.system.nm('tag', '+project/personal', '--', 'id:move@example.org')
        duplicate = self.system.mail_root / '.Archive/cur/duplicate:2,S'
        shutil.copy2(first, duplicate)
        self.system.index()
        self.assertEqual(self.count('id:move@example.org and tag:inbox'), 1)
        first.unlink()
        self.system.index()
        self.assertEqual(self.count('id:move@example.org and tag:inbox'), 0)
        self.assertEqual(self.count('id:move@example.org and tag:category/finance and tag:project/personal'), 1)
        duplicate.rename(self.system.mail_root / '.Trash/cur/duplicate:2,S')
        self.system.index()
        self.assertEqual(self.count('id:move@example.org and tag:trash'), 1)

    def test_repeated_index_does_not_reapply_removed_category(self):
        self.system.index()
        self.message('bank', sender='Bank <notice@dnb.no>')
        self.system.index()
        self.system.nm('tag', '-category/finance', '--', 'id:bank@example.org')
        self.system.index()
        self.assertEqual(self.count('tag:category/finance'), 0)

    def test_metadata_tagging_preserves_conflicting_duplicate_read_flags(self):
        read = self.message('duplicate', sender='Bank <notice@dnb.no>', flags='S')
        unread = self.system.mail_root / '.Archive/cur/second-copy:2,'
        unread.write_bytes(read.read_bytes())
        self.system.index()
        self.system.apply_history()
        self.assertTrue(read.is_file(), 'A category operation rewrote the read copy')
        self.assertTrue(unread.is_file(), 'A category operation rewrote the unread copy')
        self.assertEqual(self.count('id:duplicate@example.org and tag:category/finance'), 1)

    def test_classification_failure_retains_new_queue(self):
        self.system.index()
        self.message('new')
        original = self.system.run
        def fail(args, **kwargs):
            if args[0] == 'afew':
                raise MailError('afew failed')
            return original(args, **kwargs)
        with patch.object(self.system, 'run', side_effect=fail):
            with self.assertRaises(MailError):
                self.system.index()
        self.assertEqual(self.count('tag:new'), 1)
        self.system.index()
        self.assertEqual(self.count('tag:new'), 0)

    def test_interrupted_bootstrap_does_not_classify_historical_mail(self):
        self.message('old', sender='Bank <notice@dnb.no>')
        self.system.database.mkdir(parents=True, exist_ok=True)
        # Simulate interruption after notmuch's initial import, before queue migration.
        self.system.nm('new', '--no-hooks')
        self.assertTrue(self.system.database_exists())
        self.system.index()
        self.assertEqual(self.count('tag:history-pending'), 1)
        self.assertEqual(self.count('tag:category/finance'), 0)

    def test_lock_and_background_credentials_never_prompt(self):
        with self.system.lock():
            with self.assertRaises(MailError):
                with self.system.lock():
                    self.fail('Overlapping lock accepted')
        self.system.scheduled = True
        failure = subprocess.CompletedProcess([], 2, '', '[GNUPG:] ERROR pkdecrypt_failed 67108949\nsensitive backend error')
        with patch.object(self.system, 'run', return_value=failure) as run:
            with self.assertRaisesRegex(MailError, 'unlock required'):
                self.system.secret('mail')
            command = run.call_args.args[0]
            self.assertEqual(command[0], 'gpg')
            self.assertIn('error', command)
            self.assertIn('--batch', command)
        with patch.object(self.system, 'secret', side_effect=MailUnlockRequired('mail: unlock required')), patch.object(self.system, 'run') as run:
            with self.assertRaises(MailError):
                self.system.sync()
            run.assert_not_called()
        status = json.loads((self.system.state / 'mail-status.json').read_text())
        self.assertEqual(status['state'], 'unlock-required')

    def test_overlapping_sync_preserves_active_operation_status(self):
        for component,operation in [('mail',self.system.sync),('contacts',lambda:mailcontacts.sync(self.system))]:
            self.system.status(component,'running','Existing operation')
            path=self.system.state/(component+'-status.json');before=path.read_bytes()
            with self.system.lock(component):
                with self.assertRaises(MailBusy):operation()
            self.assertEqual(path.read_bytes(),before)

    def test_sync_reports_phase_and_streams_only_foreground_transport(self):
        for scheduled in (False, True):
            self.system.scheduled = scheduled
            observed = []
            def transport(*args, **kwargs):
                status = json.loads((self.system.state / 'mail-status.json').read_text())
                observed.append(status['message'])
                self.assertEqual(kwargs['live'], not scheduled)
            def index():
                status = json.loads((self.system.state / 'mail-status.json').read_text())
                observed.append(status['message'])
            with patch.object(self.system, 'secret'), patch.object(self.system, 'database_exists', return_value=True), patch.object(self.system, 'run', side_effect=transport), patch.object(self.system, 'index_locked', side_effect=index):
                self.system.sync()
            self.assertEqual(observed, ['Syncing Maildirs with IMAP server',
                                        'Indexing and classifying synced mail'])
            status = json.loads((self.system.state / 'mail-status.json').read_text())
            self.assertEqual(status['state'], 'ok')
            self.assertIn('last_success', status)

    def test_palette_dispatch_cancel_and_folder_safety(self):
        actions = json.loads((ROOT / 'actions.json').read_text())
        filtered = [a for a in actions if 'index' in a['contexts'] and a['key'] != '<F1>' and a['action'] != 'noop']
        reply_index = next(i for i, a in enumerate(filtered) if a['action'] == 'reply')
        output = io.StringIO()
        with patch.object(mailui, 'choose', return_value=reply_index), redirect_stdout(output):
            mailui.palette(self.system, 'index')
        self.assertEqual(output.getvalue(), 'push "<reply>"\n')
        output = io.StringIO()
        with patch.object(mailui, 'choose', return_value=None), redirect_stdout(output):
            mailui.palette(self.system, 'compose')
            mailui.folders(self.system)
        self.assertEqual(output.getvalue(), '')
        self.mkdir('.evil<enter>')
        with patch.object(mailui, 'choose', return_value=None) as choose:
            mailui.folders(self.system)
        rows = choose.call_args.args[0]
        self.assertTrue(any('With spaces.æøå' in row for row in rows))
        self.assertFalse(any('evil' in row for row in rows))

    def test_attachment_collisions_traversal_and_unicode_pdf(self):
        message = EmailMessage()
        message['Subject'] = 'Blåbær på øya'
        message.set_content('Vedlagt ligger kvitteringen.\nÆØÅ æøå')
        message.add_attachment(b'first', maintype='application', subtype='octet-stream', filename='../../receipt.txt')
        message.add_attachment(b'second', maintype='application', subtype='octet-stream', filename='receipt.txt')
        paths = mailui.attachments(self.system, message)
        self.assertEqual([p.name for p in paths], ['receipt.txt', 'receipt-1.txt'])
        self.assertEqual(paths[0].read_bytes(), b'first')
        pdf = mailui.export_pdf(self.system, message.as_bytes())
        text = subprocess.run(['pdftotext', str(pdf), '-'], capture_output=True, text=True, check=True).stdout
        self.assertIn('ÆØÅ æøå', text)
        self.assertIn('Blåbær på øya', text)

    def test_contact_staging_dedup_and_write_guard(self):
        book = self.base / 'book'
        book.mkdir()
        name, data = mailcontacts.make_card('Test Æøå', 'person@example.org')
        (book / name).write_bytes(data)
        self.assertEqual(mailcontacts.email_addresses(book), {'person@example.org'})
        baseline = mailcontacts.snapshot(book)
        new_name, new_data = mailcontacts.make_card('New', 'new@example.org')
        (book / new_name).write_bytes(new_data)
        mailcontacts.validate_addition(book, baseline, new_name)
        (book / name).unlink()
        with self.assertRaises(MailError):
            mailcontacts.validate_addition(book, baseline, new_name)

    def test_readonly_vdirsyncer_and_reviewed_publication_with_filesystem_storages(self):
        source, target = self.base / 'server', self.base / 'mirror'
        source.mkdir()
        target.mkdir()
        name, data = mailcontacts.make_card('Original', 'original@example.org')
        (source / name).write_bytes(data)
        config = self.base / 'vdir.conf'
        def configure(readonly):
            partial = 'partial_sync = "revert"' if readonly else ''
            config.write_text(f'''[general]\nstatus_path = "{self.base}/vdir-state"\n[pair test]\na = "local"\nb = "remote"\ncollections = null\n{partial}\n[storage local]\ntype = "filesystem"\npath = "{target}"\nfileext = ".vcf"\n[storage remote]\ntype = "filesystem"\npath = "{source}"\nfileext = ".vcf"\nread_only = {str(readonly).lower()}\n''')
        configure(True)
        self.system.run(['vdirsyncer', '--config', config, 'discover', 'test'])
        self.system.run(['vdirsyncer', '--config', config, 'sync', 'test'])
        self.assertEqual(mailcontacts.email_addresses(target), {'original@example.org'})
        extra, payload = mailcontacts.make_card('Not approved', 'unapproved@example.org')
        (target / extra).write_bytes(payload)
        self.system.run(['vdirsyncer', '--config', config, 'sync', 'test'])
        self.assertNotIn('unapproved@example.org', mailcontacts.email_addresses(source))
        baseline = mailcontacts.snapshot(target)
        approved, payload = mailcontacts.make_card('Reviewed', 'approved@example.org')
        (target / approved).write_bytes(payload)
        mailcontacts.validate_addition(target, baseline, approved)
        configure(False)
        self.system.run(['vdirsyncer', '--config', config, 'discover', 'test'])
        self.system.run(['vdirsyncer', '--config', config, 'sync', 'test'])
        self.assertEqual(mailcontacts.email_addresses(source), {'original@example.org', 'approved@example.org'})

    def test_address_history_does_not_create_contacts(self):
        self.message('alice', sender='Alice Ødegård <alice@example.org>')
        self.system.index()
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertTrue(mailui.query_addresses(self.system, 'Alice'))
        self.assertIn('alice@example.org', output.getvalue())
        self.assertIn('not a saved contact', output.getvalue())
        self.assertFalse(list(self.system.data.glob('contacts/**/*.vcf')))
        with redirect_stdout(io.StringIO()):
            self.assertFalse(mailui.query_addresses(self.system, 'x" or * or "'))

    def test_contact_cancel_publish_and_duplicate_are_explicit(self):
        server = self.base / 'remote-book'
        server.mkdir()
        original, data = mailcontacts.make_card('Existing', 'existing@example.org')
        (server / original).write_bytes(data)
        writes = []
        def fake_vdir(args, **kwargs):
            if args[0] != 'vdirsyncer':
                self.fail('Unexpected external command')
            config = configparser.ConfigParser()
            config.read(args[2])
            section = 'remote' if config.has_section('storage remote') else 'contacts_remote'
            local = 'local' if section == 'remote' else 'contacts_local'
            directory = Path(json.loads(config['storage ' + local]['path']))
            directory.mkdir(parents=True, exist_ok=True)
            if args[3] == 'sync':
                writable = not config['storage ' + section].getboolean('read_only')
                if writable:
                    writes.append(True)
                    for path in directory.glob('*.vcf'):
                        shutil.copy2(path, server / path.name)
                else:
                    for path in server.glob('*.vcf'):
                        shutil.copy2(path, directory / path.name)
            return subprocess.CompletedProcess(args, 0, '', '')
        message = EmailMessage()
        message['From'] = 'New Person <new@example.org>'
        terminal = unittest.mock.MagicMock()
        terminal.__enter__.return_value = terminal
        with patch.object(self.system, 'secret', return_value='test-password'), patch.object(self.system, 'run', side_effect=fake_vdir), patch.object(mailcontacts, 'read_message', return_value=message), patch.object(mailcontacts, 'Terminal', return_value=terminal):
            terminal.readline.side_effect = ['\n', '\n', 'n\n']
            mailcontacts.add_sender(self.system)
            self.assertEqual(writes, [])
            self.assertEqual(mailcontacts.email_addresses(server), {'existing@example.org'})
            terminal.readline.side_effect = ['\n', '\n', 'y\n']
            mailcontacts.add_sender(self.system)
            self.assertEqual(len(writes), 1)
            self.assertEqual(mailcontacts.email_addresses(server), {'existing@example.org', 'new@example.org'})
            terminal.readline.side_effect = AssertionError('Duplicate contact must not prompt')
            mailcontacts.add_sender(self.system)
            self.assertEqual(len(writes), 1)

    def test_tls_checks_never_send_mail(self):
        with patch('imaplib.IMAP4_SSL') as imap, patch('smtplib.SMTP') as smtp, patch.object(self.system, 'secret', return_value='test-password'):
            with redirect_stdout(io.StringIO()):
                self.system.check_connections()
            smtp.return_value.__enter__.return_value.login.assert_called_once()
            smtp.return_value.__enter__.return_value.sendmail.assert_not_called()
            smtp.return_value.__enter__.return_value.send_message.assert_not_called()
            context = smtp.return_value.__enter__.return_value.starttls.call_args.kwargs['context']
            self.assertTrue(context.check_hostname)


    def test_only_machine_coded_pin_failures_are_deferred(self):
        self.system.scheduled = True
        for stderr, expected in [
            ('[GNUPG:] NO_SECKEY redacted\n[GNUPG:] ERROR pkdecrypt_failed 67108949', MailUnlockRequired),
            ('[GNUPG:] ERROR pkdecrypt_failed 177', MailUnlockRequired),
            ('[GNUPG:] ERROR pkdecrypt_failed 11', MailUnlockRequired),
            ('[GNUPG:] ERROR pkdecrypt_failed 17', MailError),
            ('[GNUPG:] ERROR pkdecrypt_failed 9', MailError),
            ('unlock required localized or sensitive error text', MailError),
            ('[GNUPG:] ERROR pkdecrypt_failed invalid', MailError),
        ]:
            with self.subTest(stderr=stderr),patch.object(self.system,'run',return_value=subprocess.CompletedProcess([],2,'',stderr)):
                with self.assertRaises(expected) as error:
                    self.system.secret('mail')
                self.assertIs(type(error.exception),expected)
                self.assertNotIn('sensitive',str(error.exception))
        with patch.object(self.system,'run',return_value=subprocess.CompletedProcess([],0,'','')):
            with self.assertRaisesRegex(MailError,'empty'):
                self.system.secret('mail')

    def test_deferred_sync_preserves_success_for_mail_and_contacts(self):
        self.system.scheduled = True
        for component,operation in [('mail',self.system.sync),('contacts',lambda:mailcontacts.sync(self.system))]:
            self.system.status(component,'ok','Earlier successful sync')
            path=self.system.state/(component+'-status.json')
            previous=json.loads(path.read_text())['last_success']
            with patch.object(self.system,'secret',side_effect=MailUnlockRequired('unlock required')),patch.object(self.system,'run') as run:
                with self.assertRaises(MailUnlockRequired):operation()
                run.assert_not_called()
            status=json.loads(path.read_text())
            self.assertEqual(status['state'],'unlock-required')
            self.assertEqual(status['last_success'],previous)
            # Actual failures remain errors, even if a message resembles a lock.
            with patch.object(self.system,'secret',side_effect=MailError('unlock required text; actual failure')):
                with self.assertRaises(MailError):operation()
            self.assertEqual(json.loads(path.read_text())['state'],'error')


    def test_unlock_notice_only_once_until_success(self):
        self.system.scheduled = True
        for _ in range(3):
            self.system.status('mail','running','Credential preflight')
            self.system.status('mail','unlock-required','unlock required')
        self.assertEqual(self.notify.call_count,1)
        self.system.status('mail','ok','Synced')
        self.system.status('mail','unlock-required','unlock required again')
        self.assertEqual(self.notify.call_count,2)
        self.system.scheduled = False
        self.system.status('contacts','unlock-required','Interactive failure')
        self.assertEqual(self.notify.call_count,2)

    def test_mail_and_contacts_share_notification_cooldown_and_failure_is_nonfatal(self):
        success=subprocess.CompletedProcess([],0,'','')
        with patch('mailcore.shutil.which',return_value='/fake/notify-send'),patch.object(self.system,'run',return_value=success) as run:
            self.assertTrue(MailSystem.notify_unlock(self.system))
            self.assertTrue(MailSystem.notify_unlock(self.system))
            run.assert_called_once()
            self.assertIn('--urgency=normal',run.call_args.args[0])
            self.assertEqual(run.call_args.kwargs['timeout'],5)
        (self.system.state/'unlock-notification.json').unlink()
        with patch('mailcore.shutil.which',return_value='/fake/notify-send'),patch.object(self.system,'run',side_effect=MailError('No desktop bus')):
            self.assertFalse(MailSystem.notify_unlock(self.system))


    def test_contacts_announces_running_before_credential_retry(self):
        self.system.status('contacts','unlock-required','Previous attempt needed unlock')
        observed=[]
        def mirror(system):
            observed.append(json.loads((system.state/'contacts-status.json').read_text())['state'])
        with patch.object(mailcontacts,'sync_mirror',side_effect=mirror):
            mailcontacts.sync(self.system)
        self.assertEqual(observed,['running'])
        self.assertEqual(json.loads((self.system.state/'contacts-status.json').read_text())['state'],'ok')

    def test_status_change_requests_only_a_cached_refresh(self):
        with patch('mailcore.Path.home',return_value=self.base),patch('mailcore.subprocess.Popen') as popen:
            helper=self.base/'.local/bin/cq_maintenance';helper.parent.mkdir(parents=True);helper.write_text('# fixture')
            MailSystem.notify_maintenance(self.system)
        self.assertEqual(popen.call_args.args[0],[str(helper),'notify'])
        self.assertTrue(popen.call_args.kwargs['start_new_session'])


if __name__ == '__main__':
    unittest.main()
