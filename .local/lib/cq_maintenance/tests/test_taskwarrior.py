"""Task sync age uses successful completion only; never inspect the remote."""

import importlib.machinery, importlib.util, io, sys, unittest
from pathlib import Path
from unittest.mock import Mock, patch
import test_provision as fixtures
from test_provision import done
from cq_maintenance.providers import taskwarrior as tasks
from cq_maintenance.providers.base import Context
from cq_maintenance.model import Check
from cq_maintenance.provision import taskwarrior as setup
from cq_maintenance.provision import core
from cq_maintenance.util import Problem, atomic_json


class TaskTests(unittest.TestCase):
    setUp = fixtures.SetupTests.setUp

    def context(self):
        ctx = Context("taskwarrior", Check(provider="taskwarrior"), checking=False)
        ctx.run = Mock(return_value=done())
        return ctx

    def test_age_threshold_and_missing_timestamp(self):
        data = self.home / "tasks"
        data.mkdir()
        folder = data / "hooks"
        ctx = self.context()
        with (
            patch.object(tasks, "locations", return_value=(data, folder)),
            patch.object(tasks, "hook_ready", return_value=True),
            patch.object(tasks, "now", return_value=200000),
        ):
            self.assertEqual(tasks.check(ctx).state, "warning")
            tasks.record_success(data)
            self.assertEqual(tasks.check(ctx).state, "ok")
            atomic_json(tasks.record_path(data), {"last_success": 200000 - 86400})
            self.assertEqual(tasks.check(ctx).state, "warning")
            atomic_json(tasks.record_path(data), {"last_success": 200000 + 120})
            self.assertIsNone(tasks.check(ctx).last_success)
        ctx.run.assert_not_called()

    def test_failed_sync_preserves_last_success(self):
        data = self.home / "tasks"
        data.mkdir()
        ctx = self.context()
        tasks.record_success(data)
        before = tasks.record_path(data).read_text()
        ctx.run.return_value = done(1)
        with patch.object(tasks, "locations", return_value=(data, data / "hooks")):
            with self.assertRaisesRegex(Problem, "preserved"):
                tasks.execute(ctx, "fix")
        self.assertEqual(tasks.record_path(data).read_text(), before)

    def test_locations_disable_hooks_and_do_not_sync(self):
        data = self.home / "tasks"
        data.mkdir()
        ctx = self.context()
        ctx.run.side_effect = [done(out=str(data)), done(out="")]
        with patch.object(tasks.shutil, "which", return_value="/fake/task"):
            self.assertEqual(tasks.locations(ctx), (data, data / "hooks"))
        for call in ctx.run.call_args_list:
            self.assertIn("rc.hooks=off", call.args[0])
            self.assertIn("_get", call.args[0])
            self.assertNotIn("sync", call.args[0])

    def test_tracker_install_and_foreign_hook(self):
        data = self.home / "tasks"
        data.mkdir()
        folder = data / "hooks"
        script = tasks.source()
        script.parent.mkdir(parents=True)
        script.write_text("# fixture")
        script.chmod(0o700)
        ctx = core.context("taskwarrior", self.settings)
        with patch.object(tasks, "locations", return_value=(data, folder)):
            steps, blocked, _ = setup.plan(ctx, "apply")
            self.assertFalse(blocked)
            setup.apply(ctx, steps[0])
            self.assertEqual(setup.inspect(ctx).status, "ready")
            setup.apply(ctx, steps[0])
            tasks.hook_path(folder).unlink()
            tasks.hook_path(folder).write_text("custom")
            self.assertEqual(setup.inspect(ctx).status, "blocked")

    def test_hook_ignores_other_commands_and_records_sync(self):
        script = Path(__file__).resolve().parents[3] / "bin/cq_task-sync-hook"
        loader = importlib.machinery.SourceFileLoader("task_hook_fixture", str(script))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        hook = importlib.util.module_from_spec(spec)
        loader.exec_module(hook)
        with (
            patch.object(
                sys,
                "argv",
                [
                    str(script),
                    "command:list",
                    "data:" + str(self.home),
                    "version:3.5.0",
                ],
            ),
            patch.object(sys, "stdin", io.StringIO("fictional task\n")),
            patch.object(tasks, "record_success") as record,
        ):
            hook.main()
            record.assert_not_called()
        with (
            patch.object(
                sys,
                "argv",
                [
                    str(script),
                    "command:synchronize",
                    "data:" + str(self.home),
                    "version:3.5.0",
                ],
            ),
            patch.object(sys, "stdin", io.StringIO("")),
            patch.object(tasks, "record_success") as record,
            patch("cq_maintenance.config.load", return_value=self.settings),
            patch("subprocess.Popen"),
        ):
            hook.main()
            record.assert_called_once_with(str(self.home))

    @unittest.skipUnless(__import__("shutil").which("task"), "Taskwarrior unavailable")
    def test_real_task_sync_hook_only_records_success(self):
        import os, shlex, subprocess

        version = subprocess.run(
            ["task", "--version"], capture_output=True, text=True
        ).stdout.strip()
        if not version.startswith("3.5."):
            self.skipTest("Verified Taskwarrior 3.5 protocol")
        data = self.home / "tasks"
        data.mkdir()
        folder = data / "hooks"
        folder.mkdir()
        server = self.home / "server"
        server.mkdir()
        script = Path(__file__).resolve().parents[3] / "bin/cq_task-sync-hook"
        hook = folder / "on-exit.fixture"
        hook.write_text(
            "#!/bin/sh\nexec "
            + shlex.quote(sys.executable)
            + " "
            + shlex.quote(str(script))
            + ' "$@"\n'
        )
        hook.chmod(0o700)
        (self.home / "config.toml").write_text(
            "[checks.taskwarrior]\nenabled = false\n"
        )
        rc = self.home / "taskrc"
        base = (
            "data.location="
            + str(data)
            + "\nsync.encryption_secret=fictional-test-only-encryption-key\nnews.version=3.5.0\n"
        )
        rc.write_text(base + "sync.local.server_dir=" + str(server) + "\n")
        env = dict(
            os.environ,
            TASKRC=str(rc),
            TASKDATA=str(data),
            PYTHONPATH=str(Path(__file__).resolve().parents[2]),
        )
        result = subprocess.run(
            ["task", "sync"], env=env, capture_output=True, text=True, timeout=30
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        record = tasks.record_path(data)
        self.assertTrue(record.exists(), result.stdout)
        before = record.read_bytes()
        rc.write_text(
            base
            + "sync.server.url=http://127.0.0.1:9\nsync.server.client_id=11111111-1111-4111-8111-111111111111\n"
        )
        result = subprocess.run(
            ["task", "sync"], env=env, capture_output=True, text=True, timeout=30
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(record.read_bytes(), before)
