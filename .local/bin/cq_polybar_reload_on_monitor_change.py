#!/usr/bin/env python
#:usage: cq_polybar_reload_on_monitor_change.py
#:no-args: true
#:desc: Reload polybar when monitor outputs change.
# requirements: i3ipc

import i3ipc
import subprocess

def on_output_change(i3, e):
    subprocess.Popen(["~/.config/polybar/launch.sh"])

i3 = i3ipc.Connection()
i3.on("output", on_output_change)
i3.main()
