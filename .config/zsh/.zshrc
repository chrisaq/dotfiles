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
setopt sharehistory
setopt autocd
setopt notify
setopt interactive_comments
setopt list_types
setopt no_beep
setopt complete_in_word

# history search
# bindkey "^R" history-incremental-search-backward
# autoload -U up-line-or-beginning-search
# autoload -U down-line-or-beginning-search
# zle -N up-line-or-beginning-search
# zle -N down-line-or-beginning-search
# bindkey "^[[A" up-line-or-beginning-search # Up
# bindkey "^[[B" down-line-or-beginning-search # Down


##### history search:  arrows: local -- ctrl-r global
# setopt sharehistory
# bindkey "${key[Up]}" up-line-or-local-history
# bindkey "${key[Down]}" down-line-or-local-history
#
# up-line-or-local-history() {
#     zle set-local-history 1
#     zle up-line-or-history
#     zle set-local-history 0
# }
# zle -N up-line-or-local-history
# down-line-or-local-history() {
#     zle set-local-history 1
#     zle down-line-or-history
#     zle set-local-history 0
# }
# zle -N down-line-or-local-history
##### END: local + global history search



# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
# XDG bin as well
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
# flatpack
if [ -d "/var/lib/flatpak/exports/bin" ] ; then
    PATH="$PATH:/var/lib/flatpak/exports/bin"
fi

# update shell to include recently created group(s)
alias groups_refresh="exec sudo su -l $USER"

#####  XDG stuff #####
# should be set by pam, but missing in some places
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_RUNTIME_DIR=/run/user/`id -u`
# Setting this breaks seahorse and perhaps others
# export XDG_DATA_DIRS=""

# because xdg-utils are broken
export DE="generic"

# PAGER
export PAGER=bat

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
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export WEECHAT_HOME="$XDG_CONFIG_HOME"/weechat
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export TASKDATA="$XDG_DATA_HOME"/task
export TASKRC="$XDG_CONFIG_HOME"/task/taskrc
# temp disable
#export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
#export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config

##### XDG using aliases as workarounds
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
alias weechat='weechat -d "$XDG_CONFIG_HOME"/weechat'

### GPG stuff
export GNUPGHOME="$XDG_CONFIG_HOME"/gnupg
# use gui pinentry if we have DISPLAY _AND_ not on a SSH connection, else curses
if [[ ${DISPLAY:-}  ]] && [[ ! ${SSH_CONNECTION:-} ]]; then
    export PINENTRY_USER_DATA="USE_CURSES=0"
else
    export PINENTRY_USER_DATA="USE_CURSES=1"
    # fix pinentry
    export GPG_TTY=`tty`
fi
# when using a custom GNUPGHOME, this must be set before SSH_AUTH_SOCK to find the correct gpg-agent.conf
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

############################# zinit configuration ############################
[[ ! -f $XDG_CONFIG_HOME/zsh/zinit/bin/zinit.zsh ]] && {
    command mkdir -p $XDG_CONFIG_HOME/zsh/zinit
    command git clone https://github.com/zdharma/zinit $XDG_CONFIG_HOME/zsh/zinit/bin
}

source $ZDOTDIR/zinit/bin/zinit.zsh

# Uncomment the below if zinit is sourced after compinit
#autoload -Uz _zinit
#(( ${+_comps} )) && _comps[zinit]=_zinit

### zinit plugins
zinit ice wait'0'

zinit ice blockf
#zinit light zsh-users/zsh-completions

zinit ice depth=1; zinit light romkatv/powerlevel10k

## autosuggestions doesn't work with solarized
#zinit ice wait lucid atload'_zsh_autosuggest_start'

#zinit load zsh-users/zsh-autosuggestions

zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

zinit is-snippet for \
    OMZL::completion.zsh \
    OMZL::key-bindings.zsh \
    OMZL::directories.zsh

zinit is-snippet for \
    OMZ::plugins/git/git.plugin.zsh \
    OMZ::plugins/aws/aws.plugin.zsh \
    OMZ::plugins/sudo/sudo.plugin.zsh \
    OMZ::plugins/httpie/httpie.plugin.zsh \
    OMZ::plugins/fzf/fzf.plugin.zsh \
    OMZ::plugins/docker-compose/docker-compose.plugin.zsh \
    OMZ::plugins/kubectl/kubectl.plugin.zsh \
    OMZ::plugins/helm/helm.plugin.zsh

# zinit snippet OMZ::plugins/git/git.plugin.zsh
# zinit snippet OMZ::plugins/aws/aws.plugin.zsh
# zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
# zinit snippet OMZ::plugins/httpie/httpie.plugin.zsh
# zinit snippet OMZ::plugins/fzf/fzf.plugin.zsh
# zinit snippet OMZ::plugins/docker-compose/docker-compose.plugin.zsh
# zinit snippet OMZ::plugins/kubectl/kubectl.plugin.zsh
# zinit snippet OMZ::plugins/helm/helm.plugin.zsh

# zinit wait lucid for \
#     OMZ::plugins/kubectl/kubectl.plugin.zsh \
#     OMZ::plugins/helm/helm.plugin.zsh



zinit ice atclone"dircolors -b $HOME/.config/zsh/dircolors > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

zinit wait lucid is-snippet as"completion" for \
    OMZP::docker/_docker \
    OMZP::docker-compose/_docker-compose \
    OMZP::ripgrep/_ripgrep \
    OMZP::fd/_fd

# zinit ice as"completion"
# zinit snippet OMZ::plugins/ripgrep/_ripgrep
# zinit ice as"completion"
# zinit snippet OMZ::plugins/fd/_fd
# zinit ice as"completion"
# zinit snippet OMZ::plugins/docker/_docker



zinit light marlonrichert/zsh-autocomplete
#zinit ice pick"zcolors.plugin.zsh" src"functions/zcolors"
zinit light marlonrichert/zcolors
zinit light zdharma/zui
zinit light zdharma/zinit-crasis

zinit wait"1" lucid as"program" pick"$ZPFX/bin/fzy*" atclone"cp contrib/fzy-* $ZPFX/bin/" make"!PREFIX=$ZPFX install" for jhawthorn/fzy

##################### ENDS: zinit plugins and configuration

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


####### MISC ALIASES
alias st="st -f 'Hack Nerd Font:style=Regular:pixelsize=16'"
alias stt="tabbed -c -r 2 st -w ''"
alias sysu='systemctl --user'
alias t="task"
# the () launches the command  in a subshell, not affecting CWD of shell running the alias.
alias skraper='(cd ~/bin/Skraper && mono SkraperUI.exe)'

## terraform, iac
alias tfinit='terraform init -backend-config=tf-init.conf'

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
