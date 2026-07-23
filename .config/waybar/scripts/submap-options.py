#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["rich>=13", "typer>=0.12"]
# ///

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path
from typing import Iterable, List, Optional, Sequence, Tuple

DEFAULT_CONFIG_PATH = Path(
    os.environ.get("HYPRLAND_CONFIG", "~/.config/hypr/hyprland.conf")
).expanduser()
DEFAULT_STATE_PATH = Path("/tmp/waybar-submap-options-state.json")


def parse_bind_line(line: str) -> Optional[Tuple[str, str]]:
    rest = line[len("bind =") :].strip()
    if not rest:
        return None
    parts = [part.strip() for part in rest.split(",")]
    if not parts:
        return None
    mod = parts[0]
    key = parts[1] if len(parts) > 1 else ""
    if mod and key:
        combo = f"{mod}+{key}"
    elif key:
        combo = key
    elif mod:
        combo = mod
    else:
        combo = "bind"
    action_parts = parts[2:] if len(parts) > 2 else []
    action = ", ".join(part for part in action_parts if part)
    if not action:
        action = "?"
    return combo, action


def parse_submaps(lines: Iterable[str]) -> OrderedDict[str, List[Tuple[str, str]]]:
    submaps: OrderedDict[str, List[Tuple[str, str]]] = OrderedDict()
    current: Optional[str] = None
    for raw in lines:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("submap ="):
            name = stripped.split("=", 1)[1].strip()
            current = name or "unnamed"
            submaps.setdefault(current, [])
            continue
        if current:
            indent = len(raw) - len(raw.lstrip(" \t"))
            if indent == 0:
                continue
            if stripped.startswith("bind ="):
                bind = parse_bind_line(stripped)
                if bind:
                    submaps[current].append(bind)
    return submaps


def find_current_submap_in_json(obj: object) -> Optional[str]:
    if isinstance(obj, dict):
        for key, value in obj.items():
            lower = key.lower()
            if "submap" in lower and any(
                token in lower for token in ("current", "active", "selected")
            ):
                if isinstance(value, str) and value:
                    return value
            nested = find_current_submap_in_json(value)
            if nested:
                return nested
    elif isinstance(obj, list):
        for element in obj:
            nested = find_current_submap_in_json(element)
            if nested:
                return nested
    return None


def detect_active_submap(hyprctl_cmd: Sequence[str], timeout: float) -> Optional[str]:
    probes = []
    base = list(hyprctl_cmd)
    for suffix in (["submap"], ["binds", "-j"], ["binds"]):
        probes.append(base + suffix)
    for args in probes:
        try:
            result = subprocess.run(
                args,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
        if result.returncode != 0:
            continue
        stdout = result.stdout.strip()
        if not stdout:
            continue
        if args[-1] == "submap" or (len(args) > 1 and args[-2] == "submap"):
            for line in stdout.splitlines():
                candidate = re.search(r"submap\s*[:=]\s*(\S+)", line, re.I)
                if candidate:
                    return candidate.group(1)
            return stdout.splitlines()[0]
        try:
            payload = json.loads(stdout)
        except json.JSONDecodeError:
            continue
        active = find_current_submap_in_json(payload)
        if active:
            return active
    return None


def build_tooltip(
    submaps: OrderedDict[str, List[Tuple[str, str]]], active: Optional[str]
) -> str:
    lines: List[str] = []
    if active:
        lines.append(f"Active submap: {active}")
        lines.append("")
    if not submaps:
        lines.append("No submaps detected.")
    for name, binds in submaps.items():
        lines.append(f"{name}:")
        if not binds:
            lines.append("  (no binds defined)")
        else:
            for combo, action in binds:
                lines.append(f"  {combo} → {action}")
        lines.append("")
    tooltip = "\n".join(lines).rstrip()
    return tooltip


def summarize_active(
    submaps: OrderedDict[str, List[Tuple[str, str]]], active: Optional[str], limit: int = 4
) -> str:
    if not active:
        return ""
    entries = submaps.get(active, [])
    if not entries:
        return ""
    combos = [combo for combo, _ in entries[:limit]]
    summary = " | ".join(combos)
    if len(entries) > limit:
        summary += " ..."
    return summary


def load_state(path: Path) -> dict[str, str]:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_state(path: Path, active: Optional[str]) -> None:
    path.write_text(json.dumps({"active": active or ""}))


def build_notification_body(
    submaps: OrderedDict[str, List[Tuple[str, str]]], active: Optional[str]
) -> Optional[str]:
    if not active or active in {"default", "reset"}:
        return None
    entries = submaps.get(active, [])
    if not entries:
        return "(no binds defined)"
    return "\n".join(f"{combo} -> {action}" for combo, action in entries)


def send_notification(summary: str, body: str) -> None:
    commands = [
        [
            "dunstify",
            "-a",
            "waybar-submap",
            "-u",
            "low",
            "-t",
            "3500",
            "-h",
            "string:x-dunst-stack-tag:waybar-submap",
            summary,
            body,
        ],
        [
            "notify-send",
            "-a",
            "waybar-submap",
            "-u",
            "low",
            "-t",
            "3500",
            summary,
            body,
        ],
    ]
    for args in commands:
        try:
            result = subprocess.run(args, capture_output=True, text=True, timeout=0.5)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
        if result.returncode == 0:
            return


def maybe_notify_submap_change(
    state_path: Path,
    submaps: OrderedDict[str, List[Tuple[str, str]]],
    active: Optional[str],
) -> None:
    state = load_state(state_path)
    previous = state.get("active") or None
    save_state(state_path, active)
    if previous is None or previous == active:
        return
    body = build_notification_body(submaps, active)
    if body is None:
        return
    send_notification(f"Submap: {active}", body)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Expose Hyprland submap hints.")
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help="Path to the Hyprland configuration file.",
    )
    parser.add_argument(
        "-y",
        "--hyprctl",
        default="hyprctl",
        help="Command used to query Hyprland (usually `hyprctl`).",
    )
    parser.add_argument(
        "-t",
        "--timeout",
        type=float,
        default=0.1,
        help="Timeout in seconds for hyprctl queries.",
    )
    parser.add_argument(
        "--state-file",
        type=Path,
        default=DEFAULT_STATE_PATH,
        help="State file used to detect submap changes between polls.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config_path = args.config.expanduser()
    try:
        lines = config_path.read_text().splitlines()
    except FileNotFoundError:
        lines = []
    submaps = parse_submaps(lines)
    active = detect_active_submap((args.hyprctl,), args.timeout)
    maybe_notify_submap_change(args.state_file, submaps, active)
    tooltip = build_tooltip(submaps, active)
    summary = summarize_active(submaps, active)
    if active and summary:
        text = f"{active} [{summary}]"
    elif active:
        text = active
    else:
        text = "Submap hints"
    payload = {
        "text": text,
        "tooltip": tooltip,
    }
    json.dump(payload, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
