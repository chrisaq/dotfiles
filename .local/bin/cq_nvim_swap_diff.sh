#!/bin/bash

# Script name: vimdiff_swap.sh

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILENAME=$1


## SESSION FILE
SFPATH=$(realpath $FILENAME)
SWAPFILE=$(echo $SFPATH | sed -e 's/\//%/g').swp
# filename (and path) example
# ~/.local/state/nvim/swap//%home%chrisq%Code%Ruter%k8s-network-policy%k8s-policies.py.swp


## SESSION DIRECTORY
# default: "~/.local/state/nvim/swap/"
# SESS_DIR=$(nvim --headless -c 'echo exists("g:prosession_dir") ? g:prosession_dir : ""' -c 'quit' 2>&1 | tr -d '\r' | tr -d '\n')
SESS_DIR=$(nvim --headless -c 'echo &directory' -c 'quit' 2>&1 | tr -d '\r' | tr -d '\n')
# Expand ~ if used.
if [[ $SESS_DIR == ~* ]]; then
    SESS_DIR="${SESS_DIR/#~/$HOME}"
fi

if [ -d "$SESS_DIR" ]; then
    echo "session dir: $SESS_DIR"
    # SWAPFILE=".$(basename $FILENAME).swp"
else
    echo "session dir does not exist"
    # TODO: check some defaultish locations (CWD, ~/.local/state/nvim/swap/)
    exit 1
fi

# Full path to swapfile
SWAPPATH="${SESS_DIR}${SWAPFILE}"
echo "calculated swapfile: $SWAPPATH"


## RECOVER
if [ -f $SWAPPATH ]; then
    echo "swapfile $SWAPPATH exists"
    # Create a temporary directory for recovered file
    TMPDIR=$(mktemp -d)
    if [ -z "${TMPDIR}" ] || [ ! -d "${TMPDIR}" ]; then
        echo "ERROR: TMPDIR not set, or doesn't exist"
        exit 1
    fi
    RECOVERED_FILE="${TMPDIR}/recovered_file"
    # Recover the file
    nvim --headless -r "${FILENAME}" -c "w ${RECOVERED_FILE}" -c "quit"
    # Check if the recovered file was created
    if [ ! -f "$RECOVERED_FILE" ]; then
        echo "Failed to recover the file ${RECOVERED_FILE}"
        rm -rf "$TMPDIR"
        exit 1
    else
        echo "Recovered file: ${RECOVERED_FILE}"
        # delete swap file after recovery to different path
        rm ${SWAPPATH}
    fi
else
    echo "swapfile doesn't exist"
    exit 1
fi

## DIFF
nvim -d "$FILENAME" "$RECOVERED_FILE"

# Clean up the temporary directory
rm -rf "$TMPDIR"

