#!/usr/bin/env python3

import os
import socket
from pathlib import Path
import json

HOSTNAME = socket.gethostname()
HOMEDIR = Path.home()
SYNCDIR = f'{HOMEDIR}/Sync'

# Symlinks that are relevant on ALL computers
commonfile = f'{HOMEDIR}/bin/symlinks-common.json'
if not os.path.isfile(commonfile):
    commonfile = False

# Symlinks that are relevant on SPECIFIC computers
localfile = f'{HOMEDIR}/bin/symlinks-{HOSTNAME}.json'
if not os.path.isfile(localfile):
    localfile = False

def linkfiles(data):
    for pair in data:
        src, dest = pair
        print(f'source: {src}, dest: {dest}')
        if Path(f'{SYNCDIR}/{src}').exists() and not Path(f'{HOMEDIR}/{dest}').exists():
            print(f'OK: {SYNCDIR}/{src}\n\t{HOMEDIR}/{dest}')
            Path(f'{HOMEDIR}/{dest}').symlink_to(f'{SYNCDIR}/{src}')

if __name__ == "__main__":

    if commonfile:
        comjson = open(commonfile)
        comdata = json.load(comjson)
        linkfiles(comdata['synclinks'])

    if localfile:
        locjson = open(localfile)
        locdata = json.load(locjson)
        linkfiles(locdata['synclinks'])

