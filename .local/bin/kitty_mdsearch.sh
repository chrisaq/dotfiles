#!/bin/bash

# Use Zenity to prompt for input
# arg=$(zenity --entry --title="Enter Argument" --text="Provide an argument for the function:")
arg=''

# Check if Zenity was canceled or empty input
# if [ $? -eq 1 ] || [ -z "$arg" ]; then
#   echo "No argument provided. Exiting."
#   exit 1
# fi
#
# Run Kitty in a new floating window, calling the Zsh function
kitty --class "floating-mdsearch" -- zsh -c "$HOME/.local/bin/mdsearch.sh '$arg'"

