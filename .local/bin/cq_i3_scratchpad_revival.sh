#!/bin/bash

# Focus the container where the scratchpad window is located
i3-msg '[class="^.*$"] scratchpad show'

# Move all windows in the currently focused container to the current workspace
i3-msg 'move container to workspace current'

# Set the tiling mode of the current container to tabbed
i3-msg 'layout tabbed'

# Focus the new tabbed container
i3-msg '[con_mark="__focused"] focus'

# Mark the container for further reference
i3-msg 'mark __new_scratchpad'

# Make the new tabbed container a scratchpad
i3-msg '[con_mark="__new_scratchpad"] move scratchpad'

# Unmark the container
i3-msg 'unmark __new_scratchpad'
