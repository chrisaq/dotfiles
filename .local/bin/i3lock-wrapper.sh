#!/bin/bash

# lock screen by turning it black, as "blanking" it will cause monitor to go to sleep
# also set the xset commands in i3/config
i3lock -n -c 000000

# After unlock, poke YubiKey
gpg --card-status > /dev/null 2>&1 &

