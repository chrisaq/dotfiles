#!/usr/bin/env bash

fzf_command='fzf'
fd_command="fd -H -E *tmp -E *cur -E *new . ${HOME}/.local/share/mail/$1 --type d"

folder="$($fd_command | $fzf_command)"

#echo $fd_command
#echo "push 'c$folder<enter>'"
push 'c$folder<enter>'
