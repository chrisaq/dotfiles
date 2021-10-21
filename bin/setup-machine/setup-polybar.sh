#!/bin/bash

sudo cp polybar/95-usb.rules /etc/udev/rules.d/
sudo udevadm trigger
