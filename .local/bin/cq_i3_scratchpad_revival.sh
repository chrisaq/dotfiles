#!/bin/bash

# Focus the container where the scratchpad window is located
# i3-msg '[class="^.*$"] scratchpad show'
i3-msg 'scratchpad show'
i3-msg 'move position center'
