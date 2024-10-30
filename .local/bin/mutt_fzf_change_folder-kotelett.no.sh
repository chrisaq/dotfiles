#!/usr/bin/env bash

# Symlink this to mutt_fzf_change_folder-<account_root_maildir_folder>.sh
# For each account and add the following to account config in mutt:
# macro index,pager g<space> ":source ~/bin/mutt_fzf_change_folder-<account_root_maildir_folder>.sh|"<return>
# E.g. macro index,pager g<space> ":source ~/bin/mutt_fzf_change_folder-kotelett.no.sh|"<return>

#fzf_command='fzf'
fd_command="fd -H -E *tmp -E *cur -E *new . ${HOME}/.local/share/mail/$1 --type d"

script="${0##*/}"
sname="${script%.sh}"
#echo sname $sname
acc=$(echo $sname| awk -F'mutt_fzf_change_folder-' '{print $2}')
#echo acc $acc

folder=`fd -H -E '*tmp' -E '*cur' -E '*new' . ${HOME}/.local/share/mail/${acc} --type d \
        | sed "s#/home/chrisq/.local/share/mail/${acc}/#\=#g" \
        | fzf`

#folder="$($fd_command | $fzf_command)"

echo "push 'c$folder<enter>'"
#push 'c$folder<enter>'
