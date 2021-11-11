#!/usr/bin/env python3

import os
excl = ['.Archives', 'cur',  'new', 'tmp', '.mbsyncstate', \
        '.uidvalidity', '.customflags', '.subscriptions'
        ]
path = "/home/chrisq/.local/share/mail/kotelett.no/"
dirs = os.listdir(path)
dirs.sort()
#print(dirs)

for md in dirs:
    exclude = False
    for ent in excl:
        if md.startswith(ent):
            exclude = True
            continue
    if not exclude:
        print(f'+"{md}" ', end='')
print()
#    if not any(x in md for x in excl):
#        print(md)
