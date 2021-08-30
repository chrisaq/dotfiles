#!/bin/bash

pacman -S interception-caps2esc
cp caps2esc/c2e.yaml /etc/interception/udevmon.d/
systemctl enable udevmon --now
