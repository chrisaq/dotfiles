# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#echo sourcing $HOME/.config/zsh/.zshrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# this shouldn't be forced here, but stuff complains
#export TERM="xterm-256color"
#
### History
# Having a HISTFILE makes every running zsh share history, which can be annoying
#HISTFILE=~/.histfile
# fc -W  # <- try writing history to file, used to test for errors
HISTFILE=$XDG_CACHE_HOME/zsh-history
SAVEHIST=10000
HISTSIZE=30000
###################### Setopts
#setopt append_history no_inc_append_history no_share_history
#setopt append_history
setopt incappendhistorytime
setopt hist_ignore_dups
setopt hist_no_functions
setopt hist_reduce_blanks
setopt autocd
setopt notify
setopt interactive_comments
setopt list_types
setopt no_beep
setopt complete_in_word

# history search
bindkey "^R" history-incremental-search-backward
#[[ -n "${key[Up]}" ]] && bindkey "${key[Up]}" history-beginning-search-backward
#[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" history-beginning-search-forward
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down


# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi


#####  XDG stuff #####
# should be set by pam, but missing in some places
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_RUNTIME_DIR=/run/user/`id -u`

# because xdg-utils are broken
export DE="generic"

##### XDG apps workarounds #####
# https://wiki.archlinux.org/index.php/XDG_Base_Directory_support
# TODO: .xinitrc, ~/.Xresources ~/.Xdefaults
export ATOM_HOME="$XDG_DATA_HOME"/atom
export HTTPIE_CONFIG_DIR="$XDG_CONFIG_HOME"/httpie
if [[ ! -d "$XDG_CACHE_HOME"/httpie ]]; then
    mkdir -p "$XDG_CACHE_HOME"/httpie
fi
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
if [[ ! -d "$XDG_CONFIG_HOME"/less ]]; then
    mkdir -p "$XDG_CONFIG_HOME"/less
fi
export LESSKEY="$XDG_CONFIG_HOME"/less/lesskey
export MEDNAFEN_HOME="$XDG_CONFIG_HOME"/mednafen
export NOTMUCH_CONFIG="$XDG_CONFIG_HOME"/notmuch/notmuchrc
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc
export __GL_SHADER_DISK_CACHE_PATH="$XDG_CACHE_HOME"/nv
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export RANDFILE="$XDG_CACHE_HOME"/rnd
export RXVT_SOCKET="$XDG_RUNTIME_DIR"/urxvt/urxvt-"$(hostname)"
export JUPYTER_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/jupyter
export IPYTHONDIR=${XDG_CONFIG_HOME:-$HOME/.config}/ipython
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export WEECHAT_HOME="$XDG_CONFIG_HOME"/weechat
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export TASKDATA="$XDG_DATA_HOME"/task
export TASKRC="$XDG_CONFIG_HOME"/task/taskrc

##### XDG using aliases as workarounds
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
alias weechat='weechat -d "$XDG_CONFIG_HOME"/weechat'

### GPG stuff
export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh
export GNUPGHOME="$XDG_CONFIG_HOME"/gnupg
# use gui pinentry if we have DISPLAY _AND_ not on a SSH connection, else curses
if [[ ${DISPLAY:-}  ]] && [[ ! ${SSH_CONNECTION:-} ]]; then
    export PINENTRY_USER_DATA="USE_CURSES=0"
else
    export PINENTRY_USER_DATA="USE_CURSES=1"
    # fix pinentry
    export GPG_TTY=`tty`
fi

############################# zplugin configuration ############################
# Installation:
# git clone https://github.com/zdharma/zplugin.git $XDG_CONFIG_HOME/zsh/zplugin/bin
[[ ! -f $XDG_CONFIG_HOME/zsh/zplugin/bin/zplugin.zsh ]] && {
    command mkdir -p $XDG_CONFIG_HOME/zsh/zplugin
    command git clone https://github.com/zdharma/zplugin $XDG_CONFIG_HOME/zsh/zplugin/bin
}

source $ZDOTDIR/zplugin/bin/zplugin.zsh

# Uncomment the below if zplugin is sourced after compinit
#autoload -Uz _zplugin
#(( ${+_comps} )) && _comps[zplugin]=_zplugin

### zplugin plugins
zplugin ice wait'0'

zplugin ice blockf
zplugin light zsh-users/zsh-completions

zplugin ice depth=1; zplugin light romkatv/powerlevel10k

## autosuggestions doesn't work with solarized
#zplugin ice wait lucid atload'_zsh_autosuggest_start'
#zplugin load zsh-users/zsh-autosuggestions

zplugin load zdharma/fast-syntax-highlighting
zplugin snippet OMZ::plugins/git/git.plugin.zsh

zplugin light zdharma/zui
zplugin light zdharma/zplugin-crasis

zplugin wait"1" lucid as"program" pick"$ZPFX/bin/fzy*" atclone"cp contrib/fzy-* $ZPFX/bin/" make"!PREFIX=$ZPFX install" for jhawthorn/fzy

##################### ENDS: zplugin plugins and configuration

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
autoload -Uz compinit
compinit

# path to user-installed ruby gems bin
if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
    PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi

# VIM stuff
# VI mode, breaks arrow history search
# bindkey -v
# emacs bindings
bindkey -e
alias vis="vim -S .vim.session"
export EDITOR=nvim

# Dotfiles in git
alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
unset GREP_OPTIONS

alias pwdcopy='pwd | tr -d "\r\n" |xclip -selection clipboard'
alias copypwd="pwdcopy"

# aws

if [[ -s /usr/bin/aws_zsh_completer.sh ]]; then
  source /usr/bin/aws_zsh_completer.sh
fi

# ag - silver searcher
alias ag="ag --hidden"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f'
# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# trigger fzf on tab, not **
#export FZF_COMPLETION_TRIGGER=''
# arch locations
FZF_BIND="/usr/share/fzf/key-bindings.zsh"
FZF_COMPL="/usr/share/fzf/completion.zsh"
[[ -f $FZF_BIND ]] && source $FZF_BIND
[[ -f $FZF_COMPL ]] && source $FZF_COMPL


HAS_FZF=0 && command -v fzf >/dev/null 2>&1 && HAS_FZF=1
if [[ $HAS_FZF -eq 1  ]]; then
    fkill() {
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

        if [ "x$pid" != "x" ]; then
            kill -${1:-9} $pid
        fi
    }
fi
# fasd
if command -v fasd >/dev/null 2>&1; then
    eval "$(fasd --init auto)"
    if [[ $HAS_FZF -eq 1  ]]; then
        unalias z
        z() {
            local dir
            dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
        }
        v() {
            local file
            file="$(fasd -Rfl "$1" | fzf -1 -0 --no-sort +m)" && vim "${file}" || return 1
        }
    else
        alias v='f -t -e vim'
    fi
fi


256tab() {
    for k in `seq 0 1`;do
        for j in `seq $((16+k*18)) 36 $((196+k*18))`;do
            for i in `seq $j $((j+17))`; do
                printf "\e[01;$1;38;5;%sm%4s" $i $i;
            done;echo;
        done;
    done; echo
    for i in {234..255}; do printf "\e[01;$1;38;5;%sm%4s" $i  $i; done; echo
}



################################################################################
# SEC section - gpg, yubikey, pass, gopass, password-store etc
#

# gpg
# restart gpg-agent on new tty
alias gpg-tty-update="gpg-connect-agent UPDATESTARTUPTTY /bye >/dev/null"
#
# #if [[ -s ${ZDOTDIR:-${HOME}}/gpg-agent.plugin.zsh ]]; then
# #  source ${ZDOTDIR:-${HOME}}/gpg-agent.plugin.zsh
# #fi
# 


export PASSWORD_STORE_DIR=$HOME/Sync/Password-Store

Pass() {
    pass=$(gopass ls -f | fzf +m) && \
    gopass -c "$pass"
}

Passy() {
    pass=$(gopass ls -f | fzy) && \
    gopass "$pass"
}

alias pass='gopass'
alias yubikey_reset_serial='echo rm ${GNUPGHOME}/private-keys-v1.d/{A7311DE4F14645F60A94FAB5A7864BDE48076BF4.key,C2BE7814190B272612D9E293BE85D9B670B76E50.key,F0B427412DD319186D0F26FB1E228AC93B4EA3BA.key} && gpg --card-status'
### Add the below, besides the alias part, to windows manager as keyboard shortcuts
# Simply copy the selected password to the clipboard
alias PassMenu="gopass ls --flat | rofi -dmenu | xargs --no-run-if-empty gopass show -c"
# First pipe the selected name to gopass, encrypt it and type the password with xdotool.
alias PassMenux="gopass ls --flat | rofi -dmenu | xargs --no-run-if-empty gopass show -f | head -n 1 | xdotool type --clearmodifiers --file -"

# Turns out the below is just an inconvenient version of fzf's ctrl-t
# ff: fd and fzy
# passes all args to command after ff, and then a file/dir as found by fzy at the end
# ex: "ff ls -l -a -d" results in the command ls -l -a -d <file/dir picked by fzy>
ff () {
    ffile=$(fd | fzy) && $1 "${@:2}" $ffile
}

### ENDS: SEC section ##########################################################

alias st="st -f 'Hack Nerd Font:style=Regular:pixelsize=16'"
alias stt="tabbed -c -r 2 st -w ''"
alias sysu='systemctl --user'

## terminfo
typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line



# Powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
