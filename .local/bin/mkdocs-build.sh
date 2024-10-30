#!/bin/bash

DOCPATH="${1}"

if [[ -f "build-init.sh" ]]; then
    echo "Running init script."
    ./build-init.sh
else
    echo "No init script exists, continuing."
fi

while inotifywait --event modify --recursive ${DOCPATH} ; do
    # execute script before mkdocs build if it exists
    if [[ -f "build-pre.sh" ]]; then
        echo "Running pre script."
        ./build-pre.sh
    else
        echo "No pre script exists, continuing."
    fi
    ## MKDOCS BUILD
    $HOME/.local/bin/mkdocs-venv/bin/mkdocs build
    # execute script after mkdocs build if it exists
    if [[ -f "build-post.sh" ]]; then
        echo "Running post script."
        ./build-post.sh
    else
        echo "No post script exists, continuing."
    fi
done
