#!/bin/env bash

# This script is used to bootstrap an installation on a new machine
echo "Installing required packages required by further installation scripts"
pacman -Suy git gpg openssh ansible

