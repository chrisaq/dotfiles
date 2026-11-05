import subprocess, unittest
from unittest.mock import Mock, patch
from test_engine import Isolated
from cq_maintenance.model import Check, Result, Settings
from cq_maintenance.dashboard import MaintenanceApp, ConfirmAction
from cq_maintenance.unit_review import UnitReview
from cq_maintenance.providers import systemd
from cq_maintenance.util import Problem


class UnitTests(Isolated):
    def test_restart_rechecks_failure_and_targets_exact_user_unit(self):
        ctx = Mock()
        ctx.run.return_value = subprocess.CompletedProcess(["systemctl"], 0)
        row = {"scope": "user", "unit": "example.service"}
        with patch.object(systemd, "failed_units", return_value=[row]):
            systemd.restart_unit(ctx, row)
        ctx.run.assert_called_once_with(
            ["systemctl", "--user", "restart", "example.service"],
            foreground=False,
            timeout=120,
        )

    def test_recovered_unit_is_not_restarted(self):
        ctx = Mock()
        row = {"scope": "user", "unit": "example.service"}
        with patch.object(systemd, "failed_units", return_value=[]):
            with self.assertRaisesRegex(Problem, "no longer failed"):
                systemd.restart_unit(ctx, row)
        ctx.run.assert_not_called()

    def test_system_restart_uses_foreground_sudo(self):
        ctx = Mock()
        ctx.run.return_value = subprocess.CompletedProcess(["sudo"], 0)
        row = {"scope": "system", "unit": "example.service"}
        with patch.object(systemd, "failed_units", return_value=[row]):
            systemd.restart_unit(ctx, row)
        ctx.run.assert_called_once_with(
            ["sudo", "systemctl", "restart", "example.service"],
            foreground=True,
            timeout=120,
        )

    def test_bad_scope_or_option_cannot_reach_systemctl(self):
        for row in [
            {"scope": "other", "unit": "a.service"},
            {"scope": "user", "unit": "--all.service"},
            {"scope": "user", "unit": "a.service x"},
        ]:
            with self.assertRaises(Problem):
                systemd.validate_unit(row)


class ReviewUITests(unittest.IsolatedAsyncioTestCase):
    async def exercise(self, operation):
        check = Check(provider="units")
        row = {"scope": "user", "unit": "cq-mail.service"}
        result = Result(
            id="failed-units",
            state="error",
            summary="1 failed units",
            metrics={"units": [row]},
        )
        settings = Settings(
            checks={"failed-units": check, "mail": Check(provider="mail")}
        )
        with (
            patch("cq_maintenance.dashboard.load", return_value=settings),
            patch("cq_maintenance.unit_review.load", return_value=settings),
            patch("cq_maintenance.dashboard.snapshot", return_value=[result]),
            patch("cq_maintenance.unit_review.check_one", return_value=result),
            patch(
                "cq_maintenance.unit_review.unit_logs", return_value="unlock required"
            ),
            patch(
                "cq_maintenance.unit_review.restart_unit",
                return_value="Restart completed",
            ) as restart,
            patch("cq_maintenance.unit_review.log_event"),
            patch.object(MaintenanceApp, "launch", return_value=0) as launch,
        ):
            app = MaintenanceApp(select="failed-units")
            async with app.run_test(size=(120, 40)) as pilot:
                await pilot.pause()
                await pilot.click("#review")
                await pilot.pause()
                await pilot.pause()
                self.assertIsInstance(app.screen, UnitReview)
                screen = app.screen
                self.assertEqual(app.selected, "failed-units")
                self.assertIn("unlock required", screen.query_one("#ur-logs").text)
                launch.assert_not_called()
                restart.assert_not_called()
                if __import__("os").environ.get("CQ_UNIT_REVIEW_SCREENSHOT"):
                    app.save_screenshot("cq-unit-review.svg", "/tmp")
                await operation(app, screen, pilot, restart, launch)

    async def test_viewing_and_cancel_do_not_restart(self):
        async def operation(app, screen, pilot, restart, launch):
            await pilot.click("#ur-restart")
            await pilot.pause()
            self.assertIsInstance(app.screen, ConfirmAction)
            await pilot.click("#cancel")
            await pilot.pause()
            restart.assert_not_called()
            launch.assert_not_called()

        await self.exercise(operation)

    async def test_confirmed_restart_is_specific_and_result_stays_visible(self):
        async def operation(app, screen, pilot, restart, launch):
            await pilot.click("#ur-restart")
            await pilot.pause()
            await pilot.click("#yes")
            await pilot.pause()
            await pilot.pause()
            restart.assert_called_once()
            self.assertEqual(
                restart.call_args.args[1], {"scope": "user", "unit": "cq-mail.service"}
            )
            self.assertIn(
                "Restart completed", str(screen.query_one("#ur-status").render())
            )

        await self.exercise(operation)

    async def test_failed_restart_is_visible_instead_of_silent(self):
        async def operation(app, screen, pilot, restart, launch):
            restart.side_effect = Problem("systemctl failed (exit 1)")
            await pilot.click("#ur-restart")
            await pilot.pause()
            await pilot.click("#yes")
            await pilot.pause()
            await pilot.pause()
            self.assertIn(
                "systemctl failed", str(screen.query_one("#ur-status").render())
            )

        await self.exercise(operation)

    async def test_unlock_action_runs_foreground_mail_repair_after_confirmation(self):
        async def operation(app, screen, pilot, restart, launch):
            await pilot.click("#ur-repair")
            await pilot.pause()
            launch.assert_not_called()
            await pilot.click("#yes")
            await pilot.pause()
            launch.assert_called_once_with(["fix", "mail", "--yes"])
            restart.assert_not_called()

        await self.exercise(operation)
