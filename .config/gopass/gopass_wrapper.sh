#!/bin/sh

#if [ -f ~/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
#	source ~/.gpg-agent-info
#	export GPG_AGENT_INFO
#else
#	eval $(gpg-agent --daemon)
#fi

export PASSWORD_STORE_DIR=$HOME/Sync/Password-Store
export GNUPGHOME=$HOME/.config/gnupg
export GPG_TTY="$(tty)"

/usr/bin/gopass-jsonapi listen

exit $?
