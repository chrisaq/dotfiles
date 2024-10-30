#!/usr/bin/env python3

import os
excl = ['.Archives', 'cur',  'new', 'tmp', '.mbsyncstate', \
        '.uidvalidity', '.customflags', '.subscriptions', \
        '[Gmail]', 'INBOX'
        ]
path = "/home/chrisq/.local/share/mail/gmail/"
dirs = os.listdir(path)
dirs.sort()
#print(dirs)
gpre = '[Gmail]/'
gdirs = [gpre + p for p in os.listdir(path + gpre)]
#print(gdirs)

for md in dirs + gdirs:
    #print(md)
    exclude = False
    for ent in excl:
        if md.endswith(ent):
            exclude = True
            continue
    if not exclude:
        print(f'+"{md}" ', end='')
print()
#    if not any(x in md for x in excl):
#        print(md)
