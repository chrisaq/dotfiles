#!/bin/bash

DOCPATH="${1}"

#if [[ ! -L "ManualsDocs" ]]
#    ln -s $HOME/Sync/ManualsDocs .
#fi

while inotifywait --event modify --recursive ${DOCPATH} ; do
    $HOME/bin/mkdocs-venv/bin/mkdocs build
done
