"""Headless setup UI: fictional observations, no backend commands."""

import os, sys, unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from textual.widgets import Button
from cq_maintenance.dashboard import MaintenanceApp
from cq_maintenance.model import Settings
from cq_maintenance.config import SETUP_DEFAULTS
from cq_maintenance.provision.model import Observation, Plan, Step
from cq_maintenance.provision.ui import SetupScreen


class SetupUITests(unittest.IsolatedAsyncioTestCase):
    async def exercise(self, size, theme, blocked=False):
        settings = Settings(theme=theme, setup=SETUP_DEFAULTS)
        observations = [
            Observation(
                id=k,
                status="required" if k == "gopass-jsonapi" else "ready",
                summary="Browser environment needs configuration"
                if k == "gopass-jsonapi"
                else "Ready",
                details=[
                    "Set GNUPGHOME and PASSWORD_STORE_DIR; preserve extension permissions."
                ]
                if k == "gopass-jsonapi"
                else [],
            )
            for k in settings.setup
        ]

        def plan(id, action="apply"):
            return Plan(
                id=id,
                action=action,
                steps=[
                    Step(
                        id=id,
                        kind="browser",
                        title="Configure selected native host and store environment",
                    )
                ],
                blockers=["Restore GPG home first"] if blocked else [],
            )

        with (
            patch("cq_maintenance.dashboard.load", return_value=settings),
            patch("cq_maintenance.dashboard.snapshot", return_value=[]),
            patch("cq_maintenance.provision.ui.load", return_value=settings),
            patch("cq_maintenance.provision.ui.inspect_all", return_value=observations),
            patch("cq_maintenance.provision.ui.plan", side_effect=plan),
            patch("cq_maintenance.provision.ui.read_json", return_value=[]),
            patch.object(MaintenanceApp, "launch", return_value=0) as launch,
        ):
            app = MaintenanceApp(select="gopass-jsonapi", view="setup")
            async with app.run_test(size=size) as pilot:
                await pilot.pause()
                await app.workers.wait_for_complete()
                await pilot.pause()
                screen = app.screen
                self.assertIsInstance(screen, SetupScreen)
                if size[0] < 110:
                    self.assertEqual(
                        screen.query_one("#su-body").styles.layout.name, "vertical"
                    )
                self.assertEqual(screen.selected, "gopass-jsonapi")
                self.assertEqual(screen.current_plan.id, "gopass-jsonapi")
                self.assertEqual(
                    screen.query_one("#su-apply", Button).disabled, blocked
                )
                launch.assert_not_called()
                if os.environ.get("CQ_SETUP_PREVIEW"):
                    app.save_screenshot(f"setup-{theme}-{size[0]}.svg", path="/tmp")
                if not blocked:
                    screen.apply_selected()
                    await pilot.pause()
                    self.assertEqual(
                        launch.call_args.args[0][:2], ["setup-apply", "gopass-jsonapi"]
                    )
                    self.assertIn("--expected-plan", launch.call_args.args[0])
                await pilot.press("escape")
                await pilot.pause()
                self.assertNotIsInstance(app.screen, SetupScreen)

    async def test_dark(self):
        await self.exercise((120, 38), "macchiato")

    async def test_light_narrow(self):
        await self.exercise((80, 24), "latte")

    async def test_blocked(self):
        await self.exercise((60, 24), "macchiato", True)
