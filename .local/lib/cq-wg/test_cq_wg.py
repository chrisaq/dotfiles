import contextlib
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

loader = importlib.machinery.SourceFileLoader("cq_wg", str(Path(__file__).with_name("cq-wg")))
wg = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(wg)

HOME = {"link": "wg-home", "address": "10.100.0.51/32", "dns": ["10.1.0.1"],
        "domains": ["~internal.example"], "routes": [{"destination": "10.1.0.0/16"}],
        "peers": [{"public_key": "fixture-key", "endpoint": "vpn.example:51820"}]}
FULL = {**HOME, "link": "wg-full", "routes": [{"destination": "0.0.0.0/0"}]}
CONFIG = {"profiles": {"home": HOME, "full": FULL},
          "policy": {"default": "home", "off": ["Home"], "home": [], "full": ["Full"]}}
LINK = {"Kind": "wireguard", "NetworkFile": "fixture.network", "NetDevFile": "fixture.netdev"}
ARGS = SimpleNamespace(target=[], ping_count=1, ping_timeout=1, verbose=False, dry_run=False)


class SuiteTest(unittest.TestCase):
    def test_manual_off_persists_and_expires_on_ssid_change(self):
        state = {"override": {"ssid": "Cafe", "mode": "off"}}
        self.assertEqual(wg.intent(CONFIG, state, None), ("off", "manual"))
        self.assertEqual(wg.intent(CONFIG, state, "Cafe"), ("off", "manual"))
        self.assertEqual(wg.intent(CONFIG, state, "Other"), ("home", "automatic"))
        self.assertEqual(state, {})

    def test_reconnect_restores_manual_mode_after_disconnect(self):
        state = {"override": {"mode": "full", "ssid": "Cafe"}}
        wg.remember_mode(state, "off", "full", "manual", "Cafe")
        wg.remember_mode(state, "off", "off", "manual", "Cafe")
        self.assertEqual(wg.resume_mode(CONFIG, state, "Cafe"), "full")
        self.assertEqual(wg.intent(CONFIG, state, "Cafe"), ("full", "manual"))

    def test_reconnect_restores_auto_without_overriding_an_off_policy(self):
        state = {}
        wg.remember_mode(state, "off", "home", "automatic", "Cafe")
        self.assertEqual(wg.resume_mode(CONFIG, state, "Cafe"), "home")
        self.assertEqual(wg.intent(CONFIG, state, "Cafe"), ("home", "automatic"))
        wg.remember_mode(state, "off", "off", "automatic", "Home")
        with self.assertRaisesRegex(wg.Failure, "No tunnel selected"):
            wg.resume_mode(CONFIG, state, "Home")

    def test_portal_timeout_restores_manual_mode(self):
        state = {"override": {"ssid": "Cafe", "mode": "home"},
                 "portal": {"ssid": "Cafe", "until": time.monotonic() + 60}}
        self.assertEqual(wg.intent(CONFIG, state, "Cafe"), ("off", "portal"))
        state["portal"]["until"] = 0
        self.assertEqual(wg.intent(CONFIG, state, "Cafe"), ("home", "manual"))

    def test_policy_detects_down_and_retries_a_failed_activation(self):
        up = set()
        activate = Mock(side_effect=[wg.Failure("up failed"), ""])
        def command(*args):
            result = activate(*args)
            up.add(args[2])
            return result
        with patch.object(wg, "describe", return_value=LINK), patch.object(
                wg, "is_up", side_effect=lambda iface: iface in up), patch.object(
                wg, "run", side_effect=command):
            _, level, notes = wg.status_profile(CONFIG, "home", "home", "automatic")
            self.assertEqual(level, "fault")
            self.assertIn("administrative link is down", notes[0])
            with self.assertRaisesRegex(wg.Failure, "up failed"):
                wg.reconcile(CONFIG, "home")
            wg.reconcile(CONFIG, "home")
            self.assertEqual(up, {"wg-home"})
            self.assertEqual(activate.call_count, 2)

    def test_full_recursion_guard_precedes_any_link_change(self):
        with patch.object(wg, "describe", return_value=LINK), patch.object(
                wg, "read_peers", return_value={"fixture-key": "203.0.113.1:51820"}), patch.object(
                wg, "route", return_value={"dst": "default", "dev": "wlan0"}), patch.object(
                wg, "ip_json", return_value=[{"table": "main", "src": "all"}]), patch.object(
                wg, "run", return_value="off") as run:
            with self.assertRaisesRegex(wg.Failure, "can capture it"):
                wg.reconcile(CONFIG, "full")
            run.assert_called_once_with("wg", "show", "wg-full", "fwmark")

    def test_stale_endpoint_reset_updates_only_matching_peer(self):
        with patch.object(wg, "is_up", return_value=False), patch.object(wg, "preflight"), patch.object(wg, "resolve", return_value=["203.0.113.2:51820"]), patch.object(
                wg, "read_peers", return_value={"fixture-key": "203.0.113.1:51820", "unrelated-key": "(none)"}), patch.object(
                wg, "route", return_value={"dev": "wlan0"}), patch.object(wg, "uplink", return_value="wlan0"), patch.object(
                wg, "reconcile") as reconcile, patch.object(wg, "diagnose", return_value=0), patch.object(
                wg, "run", return_value="off") as run, contextlib.redirect_stdout(io.StringIO()):
            wg.reset(CONFIG, "home", "home", "automatic", "wlan0", ARGS)
            run.assert_any_call("wg", "set", "wg-home", "peer", "fixture-key", "endpoint", "203.0.113.2:51820")
            self.assertEqual(run.call_count, 2)
            reconcile.assert_called_once_with(CONFIG, "home")

    def test_dry_run_only_reads_and_prints(self):
        args = SimpleNamespace(**{**vars(ARGS), "dry_run": True})
        with patch.object(wg, "is_up", return_value=False), patch.object(wg, "preflight"), patch.object(
                wg, "resolve", return_value=["203.0.113.2:51820"]), patch.object(
                wg, "read_peers", return_value={"fixture-key": "(none)"}), patch.object(
                wg, "route", return_value={"dev": "wlan0"}), patch.object(wg, "uplink", return_value="wlan0"), patch.object(
                wg, "reconcile") as reconcile, patch.object(wg, "run", return_value="off") as run, contextlib.redirect_stdout(io.StringIO()) as output:
            wg.reset(CONFIG, "home", "home", "automatic", "wlan0", args)
            self.assertIn("activate; refresh 1", output.getvalue())
            run.assert_called_once_with("wg", "show", "wg-home", "fwmark")
            reconcile.assert_not_called()

    def test_probe_failures_distinguish_handshake_from_dns(self):
        for level, expected in (("pending", "handshake not verified"), ("ok", "DNS server failed")):
            with self.subTest(level=level), patch.object(
                    wg, "status_profile", return_value=(True, level, [])), patch.object(
                    wg, "probe", return_value=(True, ["DNS server failed"])), patch.object(
                    wg, "endpoint_diagnostics", return_value=[]), contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(wg.diagnose(CONFIG, ["home"], "home", "automatic", ARGS), 1)
                self.assertIn(expected, output.getvalue())
                self.assertNotIn("fixture-key", output.getvalue())

    def test_waybar_status_and_stale_snapshot(self):
        for level, age, expected in (("ok", 0, "wg-home"), ("off", 0, "VPN off"),
                                     ("fault", 0, "VPN !"), ("ok", 61, "VPN ?")):
            with self.subTest(level=level, age=age), tempfile.TemporaryDirectory() as directory, patch.object(
                    wg, "RUNTIME", Path(directory)), contextlib.redirect_stdout(io.StringIO()) as output:
                wg.save("status.json", {"time": time.monotonic() - age, "level": level,
                                        "iface": "wg-home", "detail": "fixture"}, 0o644)
                wg.render_status(True)
                self.assertEqual(json.loads(output.getvalue())["text"], expected)


if __name__ == "__main__":
    unittest.main()
