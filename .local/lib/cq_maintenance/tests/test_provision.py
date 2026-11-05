"""Setup regression tests: all files and subprocesses stay in a fictional home."""

import json, os, subprocess, sys, tempfile, unittest
from pathlib import Path
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from cq_maintenance import config, engine
from cq_maintenance.model import Settings, Check, now
from cq_maintenance.provision import core, browser, packages, recipes, units
from cq_maintenance.provision.model import SetupItem, Step, Observation
from cq_maintenance.util import Problem, atomic_json, state_dir


def done(code=0, out=""):
    return subprocess.CompletedProcess([], code, out, "")


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        env = {
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_STATE_HOME": str(self.home / "state"),
            "XDG_CACHE_HOME": str(self.home / "cache"),
            "XDG_RUNTIME_DIR": str(self.home / "runtime"),
            "CQ_MAINTENANCE_CONFIG": str(self.home / "config.toml"),
        }
        p = patch.dict(os.environ, env)
        p.start()
        self.addCleanup(p.stop)
        self.settings = Settings(
            checks={
                "mail": Check(provider="mail", enabled=False),
                "contacts": Check(provider="mail", options={"component": "contacts"}),
            },
            setup=config.SETUP_DEFAULTS,
        )
        p = patch("cq_maintenance.provision.core.load", return_value=self.settings)
        p.start()
        self.addCleanup(p.stop)
        self.ctx = core.context("gopass-jsonapi", self.settings)
        self.ctx.run = Mock(return_value=done())

    def fixture(self):
        for value in browser.environment(self.ctx).values():
            Path(value).mkdir(parents=True)
        root = browser.root_config()
        root.parent.mkdir(parents=True, exist_ok=True)
        root.write_text(
            "[core]\ncustom = yes\n[mounts]\npath = /tmp/old\nwork = /keep\n"
        )
        wrapper, targets = browser.paths(self.ctx)
        wrapper.write_text(
            "#!/bin/sh\n# custom comment\nexport GNUPGHOME=/old\nexport PASSWORD_STORE_DIR=/old\nexec /usr/bin/gopass-jsonapi listen\n"
        )
        wrapper.chmod(0o755)
        for _, path in targets:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(
                    {
                        "name": "com.justwatch.gopass",
                        "type": "stdio",
                        "path": str(wrapper),
                        "allowed_extensions": ["my-extension"],
                        "custom": True,
                    }
                )
            )
        return root, wrapper, targets[0][1]

    def test_typed_config_and_local_toggle(self):
        self.assertIsInstance(self.settings.setup["paru"], SetupItem)
        self.assertEqual(
            Settings.model_validate_json(self.settings.model_dump_json()), self.settings
        )
        config.toggle_setup("paru", False)
        self.assertFalse(config.load().setup["paru"].enabled)
        self.assertFalse((self.home / "config.toml").exists())
        self.assertTrue(config.load().setup["gopass-jsonapi"].enabled)

    def test_browser_repair_preserves_customization_and_is_idempotent(self):
        root, wrapper, manifest = self.fixture()
        before = root.read_text()
        self.ctx.expected = {
            str(p): core.fingerprint(p) for p in browser.watched(self.ctx)
        }
        browser.apply(self.ctx)
        self.assertIn("work = /keep", root.read_text())
        self.assertIn("custom = yes", root.read_text())
        self.assertEqual(
            browser.configured_root(), str(self.home / "Sync/Password-Store")
        )
        self.assertIn("# custom comment", wrapper.read_text())
        self.assertEqual(wrapper.stat().st_mode & 0o777, 0o700)
        self.assertEqual(
            json.loads(manifest.read_text())["allowed_extensions"], ["my-extension"]
        )
        self.assertTrue(json.loads(manifest.read_text())["custom"])
        self.assertEqual(
            (self.ctx.recovery / root.relative_to(self.home)).read_text(), before
        )
        self.assertEqual(browser.inspect(self.ctx), ([], []))
        mtime = wrapper.stat().st_mtime_ns
        browser.apply(self.ctx)
        self.assertEqual(wrapper.stat().st_mtime_ns, mtime)
        self.assertTrue(
            all(str(c.args[0][0]) == "sh" for c in self.ctx.run.call_args_list)
        )

    def test_inspection_never_configures_installs_or_decrypts(self):
        self.fixture()
        with (
            patch.object(packages, "arch", return_value=True),
            patch.object(packages, "installed", return_value=True),
            patch.object(recipes.shutil, "which", return_value="/fake/tool"),
        ):
            result = recipes.get("browser").inspect(self.ctx)
        self.assertEqual(result.status, "required")
        self.ctx.run.assert_not_called()

    def test_missing_generation_is_staged(self):
        for value in browser.environment(self.ctx).values():
            Path(value).mkdir(parents=True)
        wrapper, targets = browser.paths(self.ctx)

        def run(args, **kwargs):
            if args[0] == "gopass-jsonapi":
                stage = Path(args[args.index("--path") + 1])
                self.assertNotEqual(stage, wrapper.parent)
                (stage / "gopass_wrapper.sh").write_text(
                    "#!/bin/sh\nexec gopass-jsonapi listen\n"
                )
                (stage / browser.HOST).write_text(
                    json.dumps(
                        {
                            "name": "com.justwatch.gopass",
                            "type": "stdio",
                            "path": "/staged",
                            "allowed_extensions": ["fixture"],
                        }
                    )
                )
            return done()

        self.ctx.run = run
        browser.apply(self.ctx)
        self.assertEqual(browser.inspect(self.ctx), ([], []))
        self.assertEqual(json.loads(targets[0][1].read_text())["path"], str(wrapper))

    def test_symlink_and_stale_file_refused(self):
        self.fixture()
        wrapper = browser.paths(self.ctx)[0]
        self.ctx.expected[str(wrapper)] = core.fingerprint(wrapper)
        wrapper.write_text("changed")
        with self.assertRaisesRegex(Problem, "changed since review"):
            core.replace_file(wrapper, "new", 0o700, self.ctx)
        target = self.home / "other"
        target.write_text("keep")
        wrapper.unlink()
        wrapper.symlink_to(target)
        with self.assertRaises(Problem):
            core.replace_file(wrapper, "new", 0o700, self.ctx)
        self.assertEqual(target.read_text(), "keep")

    def test_plan_deduplicates_packages_and_orders_dependencies(self):
        values = [
            Step(id="a", kind="pacman", title="a", options={"packages": ["git"]}),
            Step(
                id="b",
                kind="pacman",
                title="b",
                options={"packages": ["git", "base-devel"]},
            ),
            Step(id="build", kind="paru", title="build", requires=["a", "b"]),
        ]
        result = core.ordered(values)
        self.assertEqual([s.id for s in result], ["packages:repos", "build"])
        self.assertEqual(result[0].options["packages"], ["base-devel", "git"])
        with self.assertRaisesRegex(Problem, "cycle"):
            core.ordered([Step(id="a", kind="custom", title="a", requires=["a"])])

    def test_broken_paru_bootstrap_does_not_build_with_paru(self):
        ctx = core.context("paru", self.settings)
        ctx.run = Mock(return_value=done(1))
        with patch.object(packages, "paru_ok", return_value=False):
            steps = packages.paru_steps(ctx)
        self.assertEqual(steps[-1].kind, "paru")
        self.assertIn("git", steps[0].options["packages"])
        self.assertFalse(any("makepkg" in c.args[0] for c in ctx.run.call_args_list))
        with patch.object(packages.os, "geteuid", return_value=0):
            with self.assertRaisesRegex(Problem, "normal user"):
                packages.apply(ctx, steps[-1])

    def test_ready_browser_does_not_depend_on_paru(self):
        self.fixture()
        browser.apply(self.ctx)
        with (
            patch.object(packages, "arch", return_value=True),
            patch.object(packages, "installed", return_value=True),
            patch.object(recipes.shutil, "which", return_value="/fake"),
            patch.object(
                packages, "paru_ok", side_effect=AssertionError("No paru needed")
            ),
        ):
            self.assertEqual(
                core.plan("gopass-jsonapi", settings=self.settings).steps, []
            )

    def test_mail_timer_selection_and_foreign_units(self):
        ctx = core.context("mail", self.settings)
        ctx.run = Mock(return_value=done())
        with patch.object(
            recipes,
            "mail_info",
            return_value=(["contacts"], {"changed": ["render"]}, [], []),
        ):
            steps, blockers, _ = recipes.get("mail").plan(ctx, "apply")
            self.assertFalse(blockers)
            self.assertEqual(steps[-1].options["components"], ["contacts"])
            recipes.get("mail").apply(ctx, steps[-1])
            args = ctx.run.call_args.args[0]
            self.assertIn("cq-contacts.timer", args)
            self.assertNotIn("cq-mail.timer", args)
            p = units.directory() / "cq-contacts.service"
            p.parent.mkdir(parents=True)
            p.write_text("foreign")
            self.assertEqual(recipes.get("mail").inspect(ctx).status, "blocked")

    def test_monitor_missing_setup_survives_recent_manual_check(self):
        atomic_json(state_dir() / "collector.json", {"heartbeat": now()})
        rows = engine.snapshot(self.settings)
        self.assertEqual(next(r for r in rows if r.id == "monitor").state, "warning")
        for p, text in units.expected().items():
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
        link = units.directory() / "timers.target.wants/cq-maintenance.timer"
        link.parent.mkdir()
        link.symlink_to(units.directory() / "cq-maintenance.timer")
        self.assertIsNone(units.bootstrap_hint(self.settings))
        for c in self.settings.checks.values():
            c.enabled = False
        link.unlink()
        self.assertIsNone(units.bootstrap_hint(self.settings))

    def test_setup_hidden_by_default_and_optin_staleness(self):
        self.assertEqual(core.visible(self.settings), [])
        self.settings.setup["paru"].waybar = True
        self.assertEqual(core.visible(self.settings)[0].state, "unknown")
        atomic_json(
            state_dir() / "setup/results/paru.json",
            Observation(
                id="paru", status="unsupported", summary="Other platform"
            ).model_dump(),
        )
        self.assertEqual(core.visible(self.settings), [])

    def test_stale_plan_and_failed_dependency_stop(self):
        provider = Mock()
        provider.plan.return_value = (
            [
                Step(id="first", kind="custom", title="first"),
                Step(id="later", kind="custom", title="later", requires=["first"]),
            ],
            [],
            [],
        )
        provider.watched.return_value = []
        self.settings.setup["test"] = SetupItem(provider="test")
        with (
            patch.dict(recipes.PROVIDERS, {"test": provider}),
            patch("cq_maintenance.provision.core.signal_bar"),
        ):
            value = core.plan("test", settings=self.settings)
            self.settings.theme = "latte"
            with self.assertRaisesRegex(Problem, "Configuration changed"):
                core.apply(value, lambda _: True)
            self.settings.theme = "macchiato"
            provider.apply.side_effect = Problem("fixture failure")
            provider.inspect.return_value = Observation(
                id="test", status="required", summary="fixture"
            )
            with self.assertRaisesRegex(Problem, "fixture failure"):
                core.apply(value, lambda _: True, lambda _: None)
            self.assertEqual(provider.apply.call_count, 1)

    def test_disabled_and_unsupported(self):
        self.settings.setup["paru"].enabled = False
        self.assertEqual(core.inspect_one("paru", self.settings).status, "disabled")
        with patch.object(packages, "arch", return_value=False):
            self.assertEqual(
                core.inspect_one("gopass-jsonapi", self.settings).status, "unsupported"
            )


if __name__ == "__main__":
    unittest.main()
