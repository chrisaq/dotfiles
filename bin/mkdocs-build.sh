#!/bin/bash

DOCPATH="${1}"

while inotifywait --event modify --recursive ${DOCPATH} ; do /home/chrisq/bin/mkdocs-venv/bin/mkdocs build; done
