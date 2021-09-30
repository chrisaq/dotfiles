#!/bin/bash

sudo cp 95-usb.rules /etc/udev/rules.d/
sudo udevadm trigger
