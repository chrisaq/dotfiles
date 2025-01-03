#!/bin/env bash

# This script is used to bootstrap an installation on a new machine
# Place on an machine available on the internet and run using curl -sL https://whatever.com/new-install.sh | bash
echo "Installing required packages required by further installation scripts"
pacman -Suy git gnupg unzip openssh ansible unzip

systemctl enable sshd --now

# get ansible
# curl -L https://github.com/your-username/your-repo/archive/refs/heads/main.zip -o dotfiles-master.zip
curl -L https://github.com/chrisaq/dotfiles/archive/refs/heads/master.zip -o dotfiles-master.zip
unzip dotfiles-master.zip
cd dotfiles-master/.config/ansible

ansible-galaxy collection install kewlfft.aur

echo "Available playbooks:"
echo "ansible-playbook playbooks/005-install-basics.yml"
echo "ansible-playbook playbooks/010-network-wired.yml"
echo "ansible-playbook playbooks/015-network-wifi.yml"
echo "ansible-playbook playbooks/020-create-user.yml"
echo "after reboot:"
echo "ansible-playbook playbooks/050-user-install-aur.yml"
