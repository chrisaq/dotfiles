#!/bin/sh

#if [ -f ~/.config/gnupg/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
#	source ~/.gpg-agent-info
#	export GPG_AGENT_INFO
#else
#	eval $(gpg-agent --daemon)
#fi

#export PATH="$PATH:/usr/local/bin" # required on MacOS/brew
export GNUPGHOME="/home/chrisq/.config/gnupg"
export GPG_TTY="$(tty)"

/usr/bin/gopass jsonapi listen

exit $?
