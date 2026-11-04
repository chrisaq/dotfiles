import unittest
from unittest.mock import patch
from test_engine import Isolated
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
        from textual.widgets import Button
        with patch('cq_maintenance.dashboard.snapshot',return_value=[Result(id='sample',state='warning',summary='Review me')]),patch.object(MaintenanceApp,'launch') as launch:
            app=MaintenanceApp(select='sample')
            async with app.run_test(size=(80,40)) as pilot:
                await pilot.pause();self.assertTrue(app.screen.has_class('narrow'))
                await pilot.press('f');await pilot.pause()
                await pilot.click('#cancel');await pilot.pause()
                launch.assert_not_called()
