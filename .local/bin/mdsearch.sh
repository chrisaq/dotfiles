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

echo "mdsearch: Current directory: $PWD"

# Perform the search using ugrep
# -Q -- enable TUI
# -r -- recursive search
# -l -- list only files, not inline matches (experiment with turning off)
# -%% -- boolean patterns across whole file: AND (or just space), OR (or a bar |), NOT (or a dash -)
ugrep -Qrl -%% --fuzzy=1 --ignore-case --split --context=3 --file-type=markdown --no-confirm --view="glow --tui"
# ugrep -Qrl -%% -Z4 --split --context=3 -t markdown --no-confirm --view="glow -p"
# ugrep -Qrl -%% --split --context=3 -t markdown --no-confirm --view="glow -p" -e "$arg"
# ugrep -Qrl --smart-case --theme dark --split --context=3 -t markdown --no-confirm --view="glow -p" -e "$arg"

# Return to the original working directory
cd "$CWD" || exit

