#!/bin/bash

sudo pacman -S interception-caps2esc
sudo mkdir /etc/interception/udevmon.d/
sudo cp caps2esc/c2e.yaml /etc/interception/udevmon.d/
sudo systemctl enable udevmon --now
