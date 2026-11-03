"""Protect NeoMutt's pipe protocols and command semantics during the Typer migration."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tomllib
import unittest
from unittest.mock import patch

from typer.testing import CliRunner
from mailcore import ROOT, helper_path


SCRIPT = ROOT / 'cq_mailctl' if (ROOT / 'cq_mailctl').exists() else helper_path()
cli = runpy.run_path(str(SCRIPT))
app = cli['app']
runner = CliRunner()


class MailCLI(unittest.TestCase):
    def setUp(self):
        configuration = patch.dict(os.environ, CQ_MAIL_CONFIG=str(ROOT / 'settings.example.json'))
        configuration.start()
        self.addCleanup(configuration.stop)

    def test_script_declares_all_python_dependencies(self):
        source = SCRIPT.read_text()
        self.assertEqual(source.splitlines()[0], '#!/usr/bin/env -S uv run --script')
        block = source.split('# /// script\n')[1].split('# ///')[0]
        metadata = tomllib.loads('\n'.join(line[2:] for line in block.splitlines()))
        self.assertEqual(set(metadata['dependencies']), {
            'typer==0.27.3', 'rich==15.0.0', 'reportlab==5.0.1', 'vobject==0.9.9'})

    def test_help_and_contact_subcommands_do_not_access_credentials(self):
        with patch.object(cli['MailSystem'], 'secret') as secret:
            for command in (['--help'], ['sync', '--help'], ['contacts', '--help'],
                            ['contacts', 'add', '--help'], ['status', '--help'],
                            ['rules-apply', '--help'], ['credential', '--help']):
                result = runner.invoke(app, command)
                self.assertEqual(result.exit_code, 0, result.output)
                self.assertIn('Usage:', result.output)
            secret.assert_not_called()
        self.assertIn('Everyday use', runner.invoke(app, ['--help']).output)
        self.assertIn('--json', runner.invoke(app, ['status', '--help']).output)

    def test_rules_apply_requires_explicit_history_before_accessing_mail(self):
        with patch.object(cli['MailSystem'], 'apply_history') as apply:
            result = runner.invoke(app, ['rules-apply', '--yes'])
            self.assertEqual(result.exit_code, 2, result.output)
            self.assertIn('--history', result.output)
            apply.assert_not_called()
        with patch.object(cli['MailSystem'], 'rule_preview') as preview, patch.object(cli['MailSystem'], 'apply_history') as apply:
            result = runner.invoke(app, ['rules-apply', '--history', '--yes'])
            self.assertEqual(result.exit_code, 0, result.output)
            preview.assert_called_once_with(True)
            apply.assert_called_once_with()

    def test_notmuch_forwards_options_help_separator_and_exit_status(self):
        for arguments, forwarded in (
            (['search', '--format=json', 'tag:unread'], ['search', '--format=json', 'tag:unread']),
            (['--help'], ['--help']),
            (['--', 'search', '--sort=oldest-first', 'a b'], ['search', '--sort=oldest-first', 'a b']),
        ):
            result_process = subprocess.CompletedProcess([], 7, 'raw result\n', 'diagnostic\n')
            with patch.object(cli['MailSystem'], 'nm', return_value=result_process) as nm:
                result = runner.invoke(app, ['notmuch', *arguments], color=True)
            self.assertEqual(result.exit_code, 7, result.output)
            self.assertEqual(result.stdout, 'raw result\n')
            self.assertEqual(result.stderr, 'diagnostic\n')
            nm.assert_called_once_with(*forwarded, check=False, timeout=1800)

    def test_credential_and_source_pipe_output_remain_plain(self):
        with patch.object(cli['MailSystem'], 'secret', return_value='dummy-test-secret'):
            result = runner.invoke(app, ['credential', 'mail'], color=True)
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertEqual(result.stdout, 'dummy-test-secret\n')
        self.assertEqual(result.stderr, '')
        import mailui
        with patch.object(mailui, 'palette', side_effect=lambda system, context: print('push "<reply>"')) as palette:
            result = runner.invoke(app, ['palette', 'index'], color=True)
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertEqual(result.stdout, 'push "<reply>"\n')
        self.assertEqual(palette.call_args.args[1], 'index')
        with patch.object(cli['MailSystem'], 'secret') as secret:
            result = runner.invoke(app, ['credential', 'unknown'])
        self.assertEqual(result.exit_code, 2)
        secret.assert_not_called()

    def test_query_preserves_terms_and_no_results_exit_code(self):
        import mailui
        with patch.object(mailui, 'query_addresses', return_value=False) as query:
            result = runner.invoke(app, ['query', 'Example', 'User'])
        self.assertEqual(result.exit_code, 1)
        self.assertEqual(query.call_args.args[1], 'Example User')
        self.assertEqual(result.stdout, '')

    def test_pdf_preserves_binary_stdin_for_neomutt_printing(self):
        import mailui
        message = b'Subject: print test\n\nDecoded text: \xc3\xa6\n'
        with patch.object(mailui, 'export_pdf') as export:
            result = runner.invoke(app, ['pdf'], input=message)
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertEqual(export.call_args.args[1], message)
        self.assertEqual(export.call_args.kwargs, {'decoded': True})

    def test_status_json_and_table_preserve_full_timestamps(self):
        import tempfile
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as directory:
            stamp = '2026-11-03T18:57:12+0100'
            record = {'state': 'ok', 'last_success': stamp, 'last_attempt': stamp,
                      'message': 'Synced [literal bracket text]'}
            (Path(directory) / 'mail-status.json').write_text(json.dumps(record))
            with patch.dict(cli['status'].__globals__, MailSystem=lambda: SimpleNamespace(state=Path(directory))):
                result = runner.invoke(app, ['status', '--json'])
                self.assertEqual(result.exit_code, 0, result.output)
                data = json.loads(result.stdout)
                self.assertEqual(data['mail'], record)
                self.assertEqual(data['contacts'], {})
                result = runner.invoke(app, ['status'], terminal_width=100)
                self.assertEqual(result.exit_code, 0, result.output)
                self.assertIn(stamp, result.stdout)
                self.assertIn('[literal bracket text]', result.stdout)
