#!/bin/bash

# Define your power profiles in the order you want to cycle through them
PROFILES=("performance" "balanced" "power-saver")

# Get the current power profile
CURRENT_PROFILE=$(powerprofilesctl list | grep '*' | awk '{print $2}'| sed -e 's/\://')

# Find the index of the current profile in the PROFILES array
for i in "${!PROFILES[@]}"; do
   if [[ "${PROFILES[$i]}" = "${CURRENT_PROFILE}" ]]; then
       CURRENT_INDEX=$i
       break
   fi
done

# Calculate the next profile index
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#PROFILES[@]} ))

# Set the next power profile
NEXT_PROFILE=${PROFILES[$NEXT_INDEX]}
powerprofilesctl set $NEXT_PROFILE

# Optional: Notify the user of the change. Depend on your notification system, e.g., notify-send
notify-send "Power Profile Changed" "Current power profile: $NEXT_PROFILE"

