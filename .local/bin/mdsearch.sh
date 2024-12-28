#!/bin/bash

# Capture the argument or default to an empty string
arg="${1:-""}"

# Save the current working directory
CWD="$(pwd)"

# Change to the target directory
cd "$HOME/Sync/Wiki/Tech/Tech" || {
    echo "Failed to change directory to $HOME/Sync/Wiki/Tech/Tech"
    exit 1
}

# Perform the search using ugrep
ugrep -Qrl -%% -Z4 --split --context=3 -t markdown --no-confirm --view="glow -p"
# ugrep -Qrl -%% --split --context=3 -t markdown --no-confirm --view="glow -p" -e "$arg"
# ugrep -Qrl --smart-case --theme dark --split --context=3 -t markdown --no-confirm --view="glow -p" -e "$arg"

# Return to the original working directory
cd "$CWD" || exit
