#!/bin/bash
#:usage: cq_i3_scratchpad_revival.sh
#:no-args: true
#:desc: Show i3 scratchpad and center the window.

# Focus the container where the scratchpad window is located
# i3-msg '[class="^.*$"] scratchpad show'
i3-msg 'scratchpad show'
i3-msg 'move position center'
