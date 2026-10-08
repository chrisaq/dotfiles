#!/bin/env bash
#
# Bootstrap a fresh Arch install.
#
#   curl -sL https://kotelett.no/installer | bash
#
# Installs ansible, pulls the dotfiles, and prints the stage files to run.
# Stages are deliberately not run automatically - stage 01 needs a reboot
# before stage 02 can build AUR packages as a normal user.

set -euo pipefail

DOTFILES_REPO="https://github.com/chrisaq/dotfiles"
DOTFILES_BRANCH="master"

echo "==> Installing ansible and prerequisites"
pacman -Syu --noconfirm git unzip openssh ansible

echo "==> Enabling sshd"
systemctl enable --now sshd

echo "==> Fetching dotfiles"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -L "${DOTFILES_REPO}/archive/refs/heads/${DOTFILES_BRANCH}.zip" -o "${workdir}/dotfiles.zip"
unzip -q "${workdir}/dotfiles.zip" -d "${workdir}"
cd "${workdir}/dotfiles-${DOTFILES_BRANCH}/.config/ansible"

echo "==> Installing ansible collections"
ansible-galaxy collection install -r requirements.yml

cat <<'EOF'

Dotfiles are fetched. Run the stages in order:

  # 1. As root, from the install environment or a fresh boot:
  ansible-playbook install/workstation-stage-01.yml
  #    -> base packages, network (DHCP + WiFi), user account

  # 2. Reboot, log in as your normal user:
  ansible-playbook install/workstation-stage-02.yml
  #    -> workstation packages, AUR, WireGuard tunnels, SSID policy

  # 3. Optional extras:
  ansible-playbook install/workstation-stage-03.yml

Individual playbooks can be run on their own from this directory, e.g.:

  ansible-playbook playbooks/015-network-wifi.yml
  ansible-playbook playbooks/100-wireguard.yml

EOF
