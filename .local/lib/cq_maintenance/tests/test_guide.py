"""Startup guidance is discoverable and never executes setup just by opening it."""
import unittest
from unittest.mock import patch
from typer.testing import CliRunner
from textual.widgets import Button
from cq_maintenance.cli import app
from cq_maintenance.dashboard import MaintenanceApp
from cq_maintenance.guide import StartupGuide
from cq_maintenance.provision.ui import SetupScreen
from cq_maintenance.model import Settings


class GuideCLITests(unittest.TestCase):
    def test_help_aliases_include_quickstart(self):
        for flag in ('--help','-h'):
            with self.subTest(flag=flag):
                result=CliRunner().invoke(app,[flag])
                self.assertEqual(result.exit_code,0,result.output)
                self.assertIn('First time on a machine',result.output)
                self.assertIn('cq_maintenance setup',result.output)
                self.assertIn('cq_maintenance guide',result.output)

    def test_all_full_guide_aliases_and_noninteractive_startup(self):
        with patch('cq_maintenance.cli.run') as run,patch.object(MaintenanceApp,'run') as dashboard:
            for args in (['guide'],['help'],['h'],[]):
                with self.subTest(args=args):
                    result=CliRunner().invoke(app,args)
                    self.assertEqual(result.exit_code,0,result.output)
                    self.assertIn('First machine setup',result.output)
                    self.assertIn('setup-status',result.output)
                    self.assertIn('taskwarrior',result.output)
                    self.assertIn('config.local.toml',result.output)
            run.assert_not_called();dashboard.assert_not_called()

    def test_command_short_help_and_guide_work_without_config(self):
        with patch('cq_maintenance.cli.load',side_effect=ValueError('broken settings')):
            for args in (['setup-apply','-h'],['guide']):
                result=CliRunner().invoke(app,args)
                self.assertEqual(result.exit_code,0,result.output)


class GuideUITests(unittest.IsolatedAsyncioTestCase):
    async def exercise(self,missing,size):
        with patch('cq_maintenance.dashboard.load',return_value=Settings()),patch('cq_maintenance.dashboard.snapshot',return_value=[]),patch('cq_maintenance.dashboard.collect') as collect,patch.object(MaintenanceApp,'launch') as launch,patch('cq_maintenance.provision.units.bootstrap_hint',return_value='Missing units' if missing else None),patch('cq_maintenance.provision.ui.inspect_all',return_value=[]):
            app=MaintenanceApp(startup_guide=True)
            async with app.run_test(size=size) as pilot:
                await pilot.pause()
                if missing:self.assertIsInstance(app.screen,StartupGuide)
                else:
                    self.assertNotIsInstance(app.screen,StartupGuide)
                    await pilot.press('?');await pilot.pause()
                    self.assertIsInstance(app.screen,StartupGuide)
                # Guide fits narrow terminals and permits scrolling its content.
                button=app.screen.query_one('#guide-setup',Button)
                self.assertGreater(button.region.width,0)
                self.assertLessEqual(button.region.right,size[0])
                await pilot.press('escape');await pilot.pause()
                self.assertNotIsInstance(app.screen,StartupGuide)
                await pilot.press('h');await pilot.pause()
                self.assertIsInstance(app.screen,StartupGuide)
                await pilot.click('#guide-setup');await pilot.pause()
                self.assertIsInstance(app.screen,SetupScreen)
                await app.workers.wait_for_complete()
                collect.assert_not_called();launch.assert_not_called()
    async def test_first_run_opens_guide(self):await self.exercise(True,(80,24))
    async def test_configured_machine_can_reopen_guide(self):await self.exercise(False,(120,38))
