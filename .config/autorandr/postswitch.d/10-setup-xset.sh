#!/bin/bash

# Blank the screen instead of turning it off when idle
if [[ "$AUTORANDR_CURRENT_PROFILE" == "work" ]]; then
    # For external monitor setup
    xset -dpms
    xset s on
    xset s blank
    xset s 600
elif [[ "$AUTORANDR_CURRENT_PROFILE" == "noscreens" ]]; then
    # For laptop-only setup
    xset -dpms
    xset s off
fi
