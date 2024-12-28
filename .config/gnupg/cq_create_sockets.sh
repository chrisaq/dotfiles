#!/bin/bash

systemctl --user stop gpg-agent gpg-agent.socket
systemctl --user restart gpg-agent-ssh.socket
systemctl --user restart gpg-agent-browser.socket
systemctl --user restart gpg-agent-extra.socket
systemctl --user restart gpg-agent gpg-agent.socket
