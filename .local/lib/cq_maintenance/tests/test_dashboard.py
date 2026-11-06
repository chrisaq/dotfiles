import unittest
from unittest.mock import patch
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from cq_maintenance.dashboard import MaintenanceApp
from cq_maintenance.model import Result

class DashboardTests(unittest.IsolatedAsyncioTestCase):
    async def test_dashboard_mounts_and_shows_cached_status_without_collecting(self):
        with patch('cq_maintenance.dashboard.snapshot',return_value=[Result(id='sample',state='warning',summary='Needs attention')]),patch('cq_maintenance.dashboard.collect') as collect:
            app=MaintenanceApp(select='sample')
            async with app.run_test(size=(120,40)) as pilot:
                await pilot.pause()
                self.assertEqual(app.selected,'sample')
                self.assertEqual(app.query_one('#checks').row_count,1)
                self.assertIn('Needs attention',str(app.query_one('#detail').render()))
            collect.assert_not_called()

    async def test_narrow_layout_and_cancelled_batch_do_not_repair(self):
        with patch('cq_maintenance.dashboard.snapshot',return_value=[Result(id='sample',state='warning',summary='Review me')]),patch.object(MaintenanceApp,'launch') as launch:
            app=MaintenanceApp(select='sample')
            async with app.run_test(size=(80,40)) as pilot:
                await pilot.pause();self.assertTrue(app.screen.has_class('narrow'))
                await pilot.press('f');await pilot.pause()
                await pilot.click('#cancel');await pilot.pause()
                launch.assert_not_called()

    async def test_enabled_column_keyboard_toggle_persists_locally(self):
        import os,tempfile,tomllib
        from pathlib import Path
        from textual.widgets import Button
        from cq_maintenance import config
        with tempfile.TemporaryDirectory() as name:
            root=Path(name);shared=root/'config.toml';shared.write_text('theme = "macchiato"\n')
            env={'HOME':name,'CQ_MAINTENANCE_CONFIG':str(shared),'XDG_STATE_HOME':str(root/'state'),'XDG_RUNTIME_DIR':str(root/'runtime')}
            checks={'mail':{'provider':'mail'},'contacts':{'provider':'mail'}}
            with patch.dict(os.environ,env),patch.object(config,'DEFAULTS',checks),patch.object(config,'SETUP_DEFAULTS',{}),patch('cq_maintenance.dashboard.collect') as collect,patch.object(MaintenanceApp,'launch') as launch:
                app=MaintenanceApp(select='contacts')
                async with app.run_test(size=(80,30)) as pilot:
                    await pilot.pause()
                    table=app.query_one('#checks')
                    self.assertEqual(table.get_row('contacts')[1].plain,'Yes')
                    self.assertEqual(table.get_row('monitor')[1].plain,'Auto')
                    await pilot.press('e');await pilot.pause()
                    self.assertEqual(app.selected,'contacts')
                    self.assertEqual(table.get_row('contacts')[1].plain,'No')
                    self.assertEqual(table.get_row('contacts')[2].plain,'disabled')
                    self.assertEqual(str(app.query_one('#toggle',Button).label),'Enable (e)')
                    local=root/'config.local.toml'
                    self.assertFalse(tomllib.loads(local.read_text())['checks']['contacts']['enabled'])
                    app.repaint();await pilot.pause()
                    self.assertEqual(table.get_row('contacts')[1].plain,'No')
                    await pilot.press('e');await pilot.pause()
                    self.assertEqual(table.get_row('contacts')[1].plain,'Yes')
                    self.assertTrue(tomllib.loads(local.read_text())['checks']['contacts']['enabled'])
                    self.assertEqual(shared.read_text(),'theme = "macchiato"\n')
                    collect.assert_not_called();launch.assert_not_called()
