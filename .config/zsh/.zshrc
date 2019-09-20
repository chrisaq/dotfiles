# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#
#echo sourcing $HOME/.config/zsh/.zshrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# this shouldn't be forced here, but stuff complains
#export TERM="xterm-256color"

#####  XDG stuff #####
# should be set by pam, but missing in some places
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_RUNTIME_DIR=/run/user/`id -u`

# becuase xdg-utils are broken
export DE="generic"

##### XDG apps workarounds #####
# https://wiki.archlinux.org/index.php/XDG_Base_Directory_support
# TODO: .xinitrc, ~/.Xresources ~/.Xdefaults
export ATOM_HOME="$XDG_DATA_HOME"/atom
export HTTPIE_CONFIG_DIR="$XDG_CONFIG_HOME"/httpie
if [[ ! -d "$XDG_CACHE_HOME"/less ]]; then
    mkdir -p "$XDG_CACHE_HOME"/less
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


# Fonts:
# https://github.com/gabrielelana/awesome-terminal-fonts
# Prompt:
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k
# ln -s ~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k/powerlevel9k.zsh-theme ~/.config/zsh/.zim/modules/prompt/functions/prompt_powerlevel9k_setup
POWERLEVEL9K_INSTALLATION_PATH=~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k/powerlevel9k.zsh-theme
POWERLEVEL9K_MODE='awesome-fontconfig'
#POWERLEVEL9K_MODE='awesome-patched'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
#POWERLEVEL9K_RPROMPT_ON_NEWLINE=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline context)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv time)
POWERLEVEL9K_DIR_HOME_FOREGROUND="white"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="white"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="white"
#POWERLEVEL9K_VI_INSERT_MODE_STRING="INS"
#POWERLEVEL9K_VI_COMMAND_MODE_STRING="CMD"
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="╭─"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="╰─契"

if [[ -s ${ZDOTDIR:-${HOME}}/gpg-agent.plugin.zsh ]]; then
  source ${ZDOTDIR:-${HOME}}/gpg-agent.plugin.zsh
fi


# Source zim after theme
if [[ -s ${ZDOTDIR:-${HOME}}/.zim/init.zsh ]]; then
  source ${ZDOTDIR:-${HOME}}/.zim/init.zsh
fi

# powerline
#if command -v powerline-daemon >/dev/null 2>&1; then
#    powerline-daemon -q
#fi
#PLDIR=/usr/lib/python3.5/site-packages/
#if [ -f "${PLDIR}/powerline/bindings/zsh/powerline.zsh" ]; then
#    . ${PLDIR}/powerline/bindings/zsh/powerline.zsh
#fi

# Customize to your needs...
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=1000
setopt appendhistory autocd notify
unsetopt beep

# history search
bindkey "^R" history-incremental-search-backward
[[ -n "${key[Up]}" ]] && bindkey "${key[Up]}" history-beginning-search-backward
[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" history-beginning-search-forward

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# path to user-installed ruby gems bin
if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
    PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi

alias gpg-tty-update="gpg-connect-agent UPDATESTARTUPTTY /bye >/dev/null"

# VI mode, breaks arrow history search
# bindkey -v
# VIM stuff
alias vis="vim -S .vim.session"
export EDITOR=nvim

# Dotfiles in git
alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
unset GREP_OPTIONS

# aws

if [[ -s /usr/bin/aws_zsh_completer.sh ]]; then
  source /usr/bin/aws_zsh_completer.sh
fi

# ag - silver searcher
alias ag="ag --hidden"

# fzf
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

alias stt="tabbed -c -r 2 st -w ''"
alias st="st -f 'Hack Nerd Font:style=Regular:pixelsize=16'"
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
