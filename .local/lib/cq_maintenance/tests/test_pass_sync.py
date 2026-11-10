"""KeePass export age and foreground repair; only disposable files and fake runs."""
import os, subprocess
from unittest.mock import Mock, patch
from test_engine import Isolated
from cq_maintenance.providers import pass_sync
from cq_maintenance.providers.base import Context
from cq_maintenance.model import Check
from cq_maintenance.util import Problem


class PassSyncTests(Isolated):
    def setUp(self):
        super().setUp()
        self.store = self.home / 'password-store'
        self.store.mkdir()
        self.database = self.store / 'passwords.kdbx'
        self.database.write_bytes(b'fake encrypted database')
        (self.store / 'empty.kdbx').write_bytes(b'fake template')
        self.ctx = Context('pass-sync', Check(provider='pass_sync', options={'store': str(self.store)}), checking=False)
        self.ctx.run = Mock(return_value=subprocess.CompletedProcess([], 0))
        self.clock = 20000000
        clock = patch.object(pass_sync, 'now', return_value=self.clock)
        clock.start();self.addCleanup(clock.stop)

    def test_age_boundaries_and_checks_never_run_commands(self):
        for seconds, expected in [(0, 'ok'), (604800, 'ok'), (604801, 'warning'), (1209600, 'warning'), (1209601, 'error')]:
            with self.subTest(age=seconds):
                stamp = self.clock - seconds
                os.utime(self.database, (stamp, stamp))
                row = pass_sync.check(self.ctx)
                self.assertEqual(row.state, expected)
                self.assertEqual(row.last_success, stamp)
        self.ctx.run.assert_not_called()

    def test_missing_empty_and_future_database(self):
        self.database.unlink()
        self.assertEqual(pass_sync.check(self.ctx).state, 'error')
        self.database.touch()
        self.assertEqual(pass_sync.check(self.ctx).state, 'error')
        self.database.write_bytes(b'data')
        os.utime(self.database, (self.clock + 120, self.clock + 120))
        row = pass_sync.check(self.ctx)
        self.assertEqual(row.state, 'warning');self.assertIsNone(row.last_success)

    def test_synced_file_timestamp_counts_without_local_history(self):
        os.utime(self.database, (self.clock - 100, self.clock - 100))
        self.assertEqual(pass_sync.check(self.ctx).state, 'ok')
        self.assertFalse((self.home / 'state').exists())

    def test_export_uses_documented_base_output_and_working_directory(self):
        pass_sync.execute(self.ctx, 'fix')
        call = self.ctx.run.call_args
        self.assertEqual(call.args[0], ['cq_pass-sync', 'export', '--store', str(self.store), '--base-kdbx', str(self.store / 'empty.kdbx'), '--kdbx', str(self.database)])
        self.assertEqual(call.kwargs['cwd'], self.store)
        self.assertTrue(call.kwargs['foreground'])
        self.assertEqual(call.kwargs['env']['PASSWORD_STORE_DIR'], str(self.store))

    def test_failed_export_does_not_record_freshness(self):
        os.utime(self.database, (self.clock - 1300000, self.clock - 1300000))
        self.ctx.run.return_value = subprocess.CompletedProcess(['cq_pass-sync'], 1)
        with self.assertRaises(Problem):pass_sync.execute(self.ctx, 'fix')
        self.assertEqual(pass_sync.check(self.ctx).state, 'error')

    def test_missing_base_blocks_export(self):
        (self.store / 'empty.kdbx').unlink()
        with self.assertRaisesRegex(Problem, 'base database is missing'):pass_sync.execute(self.ctx, 'fix')
        self.ctx.run.assert_not_called()

    def test_environment_store_and_custom_relative_paths(self):
        self.ctx.config.options = {'kdbx': 'out/export.kdbx', 'base_kdbx': 'templates/base.kdbx'}
        with patch.dict(os.environ, {'PASSWORD_STORE_DIR': str(self.store)}):
            store, database, base = pass_sync.paths(self.ctx)
        self.assertEqual(store, self.store)
        self.assertEqual(database, self.store / 'out/export.kdbx')
        self.assertEqual(base, self.store / 'templates/base.kdbx')

    def test_invalid_threshold_order(self):
        self.ctx.config.options.update(warning_seconds=200, error_seconds=100)
        with self.assertRaises(Problem):pass_sync.check(self.ctx)
