#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["typer==0.27.3", "textual[syntax]==8.2.8", "pydantic==2.14.1", "pyyaml==6.0.3", "rich==15.0.0"]
# ///
"""Disposable roots and fictional secrets only; never decrypt the normal store."""

import os, sys, tempfile, unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "lib"))
import cq_conflicts as m

ui = m.load_pass_ui()


class FakeBackend:
    def __init__(self, root):
        self.root = root
        self.values = {}
        self.writes = []
        self.reads = []

    def read(self, key):
        self.reads.append(key)
        return SimpleNamespace(raw=self.values[key])

    def write(self, key, raw, message=None):
        self.writes.append((key, raw))
        self.values[key] = raw
        (self.root / (key + ".gpg")).write_bytes(b"new fictional ciphertext")

    def run(self, *args):
        assert args[:2] == ("delete", "--force")
        (self.root / (args[2] + ".gpg")).unlink()
        self.values.pop(args[2], None)

    def close(self):
        pass


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "root"
        self.root.mkdir()
        self.backend = FakeBackend(self.root)
        self.resolver = m.Resolver(self.root, self.backend)
        env = patch.dict(
            os.environ, {"XDG_STATE_HOME": str(Path(self.tmp.name) / "state")}
        )
        env.start()
        self.addCleanup(env.stop)

    def pair(self, encrypted=False, orphan=False):
        ext = ".gpg" if encrypted else ".json"
        current = self.root / ("entry" + ext)
        copy = self.root / ("entry.sync-conflict-20260101-120000-ABCDEFG" + ext)
        if not orphan:
            current.write_bytes(
                b"cipher-left" if encrypted else b'{"value":"current"}\r\n'
            )
        copy.write_bytes(
            b"cipher-right" if encrypted else b'{"value":"alternative"}\r\n'
        )
        if encrypted:
            self.backend.values = {
                "entry": "TOP-SECRET-CURRENT\nuser: fictional\n",
                copy.stem: "TOP-SECRET-ALTERNATIVE\nuser: fictional\n",
            }
        return m.discover([self.root])[0]

    def test_scan_names_only_deduplicates_overlapping_roots(self):
        self.pair(True)
        self.assertEqual(len(m.discover([self.root, self.root])), 1)
        self.assertEqual(self.backend.reads, [])

    def test_keep_current_preserves_bytes_and_archives_other(self):
        c = self.pair()
        p = self.resolver.load(c)
        backup = self.resolver.resolve(p, "current")
        self.assertEqual(c.current.read_bytes(), b'{"value":"current"}\r\n')
        self.assertFalse(c.copy.exists())
        self.assertEqual(
            (backup / "alternative.json").read_bytes(), b'{"value":"alternative"}\r\n'
        )

    def test_use_alternative_preserves_crlf_and_mode(self):
        c = self.pair()
        c.current.chmod(0o640)
        self.resolver.resolve(self.resolver.load(c), "alternative")
        self.assertEqual(c.current.read_bytes(), b'{"value":"alternative"}\r\n')
        self.assertEqual(c.current.stat().st_mode & 0o777, 0o640)

    def test_reject_stale_current(self):
        c = self.pair()
        p = self.resolver.load(c)
        c.current.write_text("new external edit")
        with self.assertRaisesRegex(m.ConflictError, "changed"):
            self.resolver.resolve(p, "alternative")
        self.assertTrue(c.copy.exists())
        self.assertEqual(c.current.read_text(), "new external edit")

    def test_reject_stale_alternative(self):
        c = self.pair()
        p = self.resolver.load(c)
        c.copy.write_text("new alternative")
        with self.assertRaises(m.ConflictError):
            self.resolver.resolve(p, "current")
        self.assertTrue(c.copy.exists())

    def test_encrypted_merge_uses_backend_and_backup_is_only_ciphertext(self):
        c = self.pair(True)
        p = self.resolver.load(c)
        b = self.resolver.resolve(p, "merged", "TOP-SECRET-MERGED\n")
        self.assertEqual(self.backend.writes, [("entry", "TOP-SECRET-MERGED\n")])
        self.assertFalse(c.copy.exists())
        for f in b.iterdir():
            self.assertNotIn(b"TOP-SECRET", f.read_bytes())

    def test_orphan_restore(self):
        c = self.pair(True, True)
        p = self.resolver.load(c)
        with self.assertRaises(m.ConflictError):
            self.resolver.resolve(p, "current")
        self.resolver.resolve(p, "alternative")
        self.assertTrue(c.current.exists())
        self.assertFalse(c.copy.exists())

    def test_orphan_can_be_explicitly_archived_without_restoring(self):
        c = self.pair(True, True)
        p = self.resolver.load(c)
        backup = self.resolver.resolve(p, "archive")
        self.assertFalse(c.current.exists())
        self.assertFalse(c.copy.exists())
        self.assertEqual(self.backend.writes, [])
        self.assertEqual((backup / "alternative.gpg").read_bytes(), b"cipher-right")

    def test_binary_and_large_files_are_not_treated_as_text(self):
        c = self.pair()
        c.copy.write_bytes(b"\x00binary")
        with self.assertRaises(m.ConflictError):
            self.resolver.load(c)
        c.copy.write_bytes(b"x" * (m.LIMIT + 1))
        with self.assertRaises(m.ConflictError):
            self.resolver.load(c)

    def test_symlink_root_escape_rejected(self):
        c = self.pair()
        p = self.resolver.load(c)
        c.current.unlink()
        c.current.symlink_to(self.root.parent / "outside")
        with self.assertRaises(m.ConflictError):
            self.resolver.resolve(p, "alternative")

    def test_failed_backend_write_retains_alternative_and_recovery(self):
        c = self.pair(True)
        p = self.resolver.load(c)
        with patch.object(
            self.backend, "write", side_effect=RuntimeError("secret failure body")
        ):
            with self.assertRaises(m.ConflictError) as caught:
                self.resolver.resolve(p, "alternative")
        self.assertNotIn("secret failure", str(caught.exception))
        self.assertTrue(c.copy.exists())
        self.assertTrue(
            list(
                (Path(self.tmp.name) / "state/cq/conflicts").glob(
                    "resolved-*/alternative.gpg"
                )
            )
        )

    def test_alternative_changed_during_encrypted_write_is_not_removed(self):
        c = self.pair(True)
        pair = self.resolver.load(c)
        original_write = self.backend.write

        def racing_write(*args, **kwargs):
            original_write(*args, **kwargs)
            c.copy.write_bytes(b"new remote ciphertext")

        with patch.object(self.backend, "write", side_effect=racing_write):
            with self.assertRaises(m.ConflictError):
                self.resolver.resolve(pair, "alternative")
        self.assertEqual(c.copy.read_bytes(), b"new remote ciphertext")

    def test_second_alternative_remains_for_review(self):
        c = self.pair()
        other = c.copy.with_name("entry.sync-conflict-20260102-120000-ABCDEFG.json")
        other.write_text("third version")
        self.resolver.resolve(self.resolver.load(c), "alternative")
        self.assertTrue(other.exists())


class UITests(unittest.IsolatedAsyncioTestCase):
    async def test_mask_reveal_diff_lock_and_cancel_do_not_mutate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            current = root / "entry.gpg"
            copy = root / "entry.sync-conflict-20260101-120000-ABCDEFG.gpg"
            current.write_bytes(b"cipher-left")
            copy.write_bytes(b"cipher-right")
            backend = FakeBackend(root)
            backend.values = {
                "entry": "FAKE-SECRET-LEFT\n",
                copy.stem: "FAKE-SECRET-RIGHT\n",
            }
            app = m.ConflictApp([root], root, ui, ui.Settings(animation=False), backend)
            async with app.run_test(size=(140, 45)) as pilot:
                await pilot.pause()
                screen = app.screen
                self.assertIsInstance(screen, m.ConflictScreen)
                self.assertEqual(backend.reads, [])
                screen.open_pair(screen.conflicts[0])
                await pilot.pause()
                self.assertIsNotNone(screen.pair)
                self.assertNotIn(
                    "FAKE-SECRET", screen.query_one("#cf-left", m.TextArea).text
                )
                screen.action_reveal()
                self.assertIn(
                    "FAKE-SECRET-LEFT", screen.query_one("#cf-left", m.TextArea).text
                )
                screen.until = 0
                screen.tick()
                self.assertNotIn(
                    "FAKE-SECRET", screen.query_one("#cf-left", m.TextArea).text
                )
                screen.action_diff()
                self.assertTrue(screen.query_one("#cf-diff-scroll").display)
                screen.resolve_choice("alternative")
                await pilot.pause()
                self.assertIsInstance(app.screen, ui.ConfirmScreen)
                screen.revealed = True
                screen.paint()
                app.on_app_blur()
                self.assertNotIn(
                    "FAKE-SECRET", screen.query_one("#cf-left", m.TextArea).text
                )
                app.screen.action_no()
                await pilot.pause()
                self.assertTrue(copy.exists())
                self.assertEqual(backend.writes, [])
                screen.action_lock()
                self.assertIsNone(screen.pair)
                self.assertEqual(screen.query_one("#cf-left", m.TextArea).text, "")

    async def test_standalone_plaintext_resolution_and_screenshots(self):
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.dict(os.environ, {"XDG_STATE_HOME": tmp + "/state"}),
        ):
            root = Path(tmp) / "docs"
            root.mkdir()
            p = root / "settings.json"
            q = root / "settings.sync-conflict-20260101-120000-ABCDEFG.json"
            p.write_text('{\n  "theme": "dark",\n  "sync": true\n}\n')
            q.write_text('{\n  "theme": "light",\n  "sync": true\n}\n')
            backend = FakeBackend(root)
            app = m.ConflictApp([root], root, ui, ui.Settings(animation=False), backend)
            with patch.object(m.subprocess, "Popen"):
                async with app.run_test(size=(140, 45)) as pilot:
                    await pilot.pause()
                    screen = app.screen
                    screen.open_pair(screen.conflicts[0])
                    await pilot.pause()
                    if os.environ.get("CQ_CONFLICT_SCREENSHOTS"):
                        output = Path("/tmp/cq-conflicts-review")
                        output.mkdir(exist_ok=True)
                        app.save_screenshot("side-by-side.svg", str(output))
                        screen.action_diff()
                        await pilot.pause()
                        app.save_screenshot("diff.svg", str(output))
                        screen.action_diff()
                        screen.action_theme()
                        await pilot.pause()
                        app.save_screenshot("latte.svg", str(output))
                    screen.resolve_choice("alternative")
                    await pilot.pause()
                    app.screen.action_yes()
                    await pilot.pause()
                    await pilot.pause()
                    self.assertEqual(
                        p.read_text(), '{\n  "theme": "light",\n  "sync": true\n}\n'
                    )
                    self.assertFalse(q.exists())
                    self.assertEqual(screen.conflicts, [])

    async def test_merge_editor_has_alternative_and_saves_only_after_final_confirmation(
        self,
    ):
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.dict(os.environ, {"XDG_STATE_HOME": tmp + "/state"}),
        ):
            root = Path(tmp) / "docs"
            root.mkdir()
            p = root / "note.txt"
            q = root / "note.sync-conflict-20260101-120000-ABCDEFG.txt"
            p.write_text("current\n")
            q.write_text("alternative\n")
            app = m.ConflictApp(
                [root], root, ui, ui.Settings(animation=False), FakeBackend(root)
            )
            with patch.object(m.subprocess, "Popen"):
                async with app.run_test(size=(100, 32)) as pilot:
                    await pilot.pause()
                    screen = app.screen
                    screen.open_pair(screen.conflicts[0])
                    await pilot.pause()
                    screen.resolve_choice("edit")
                    await pilot.pause()
                    editor = app.screen
                    self.assertEqual(
                        editor.query_one("#merge-source", m.TextArea).text,
                        "alternative\n",
                    )
                    editor.query_one("#ed-area", ui.ShellTextArea).load_text("merged\n")
                    self.assertEqual(p.read_text(), "current\n")
                    if os.environ.get("CQ_CONFLICT_SCREENSHOTS"):
                        app.save_screenshot("merge.svg", "/tmp/cq-conflicts-review")
                    editor.action_save()
                    await pilot.pause()
                    self.assertIsInstance(app.screen, ui.ConfirmScreen)
                    self.assertEqual(p.read_text(), "current\n")
                    app.screen.action_yes()
                    await pilot.pause()
                    await pilot.pause()
                    self.assertEqual(p.read_text(), "merged\n")
                    self.assertFalse(q.exists())

    async def test_small_terminal_and_empty_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            app = m.ConflictApp(
                [root], root, ui, ui.Settings(animation=False), FakeBackend(root)
            )
            async with app.run_test(size=(80, 24)) as pilot:
                await pilot.pause()
                screen = app.screen
                self.assertEqual(screen.conflicts, [])
                self.assertTrue(screen.query_one("#cf-current", m.Button).disabled)
                self.assertTrue(
                    screen.query_one("#cf-close", m.Button).region.width > 0
                )
                screen.action_close()
                await pilot.pause()

    async def test_pass_workbench_integration(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            backend = FakeBackend(root)
            backend.entries = lambda: []
            app = ui.PassTUI(root, ui.Settings(animation=False), [], backend=backend)
            async with app.run_test(size=(120, 40)) as pilot:
                await pilot.pause()
                await pilot.click("#quick-conflicts")
                await pilot.pause()
                self.assertIsInstance(app.screen, m.ConflictScreen)
                app.screen.action_close()
                await pilot.pause()
                self.assertNotIsInstance(app.screen, m.ConflictScreen)


if __name__ == "__main__":
    if "--screenshots" in sys.argv:
        sys.argv.remove("--screenshots")
        os.environ["CQ_CONFLICT_SCREENSHOTS"] = "1"
    unittest.main()
