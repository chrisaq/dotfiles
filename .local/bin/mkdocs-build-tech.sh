#!/bin/bash

while inotifywait --event modify --recursive /home/chrisq/Sync/Wiki/Tech/docs ; do /home/chrisq/bin/mkdocs-venv/bin/mkdocs build; done
