# cq: sourced by logins shell and xterms
#echo ".zshrc"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return


# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"
#ZSH_THEME="rkj-repos"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
#plugins=(git vi-mode)
plugins=(git github ssh-agent gpg-agent brew history-substring-search zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# powerline
PLDIR=/usr/lib/python3.4/site-packages/
if [ -f "${PLDIR}/powerline/bindings/zsh/powerline.zsh" ]; then
    . ${PLDIR}/powerline/bindings/zsh/powerline.zsh
fi

# Customize to your needs...
export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/srv/chains/bin
export XDG_CONFIG_HOME=$HOME/.config
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=1000
setopt appendhistory autocd notify
unsetopt beep
# vi-mode
#bindkey -v

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/chrisq/.zshrc'

fpath=(~/Code/zsh-completion $fpath)

autoload -Uz compinit
compinit
# End of lines added by compinstall

# history search
bindkey "^R" history-incremental-search-backward
bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward

# Setting the TERM
if [ "$TERM" = "xterm" ] ; then
    if [ -z "$COLORTERM" ] ; then
        if [ -z "$XTERM_VERSION" ] ; then
            echo "Warning: Terminal wrongly calling itself 'xterm', assuming color term"
            TERM="xterm-256color"
        else
            case "$XTERM_VERSION" in
            "XTerm(256)") TERM="xterm-256color" ;;
            "XTerm(88)") TERM="xterm-88color" ;;
            "XTerm") ;;
            *)
                echo "Warning: Unrecognized XTERM_VERSION: $XTERM_VERSION"
                ;;
            esac
        fi
    else
        case "$COLORTERM" in
            gnome-terminal)
                # Those crafty Gnome folks require you to check COLORTERM,
                # but don't allow you to just *favor* the setting over TERM.
                # Instead you need to compare it and perform some guesses
                # based upon the value. This is, perhaps, too simplistic.
                TERM="gnome-256color"
                ;;
            *)
                echo "Warning: Unrecognized COLORTERM: $COLORTERM"
                ;;
        esac
    fi
fi
#
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# if $VIRTUAL_ENV is defined, cd with no paramters goes to $VIRTUAL_ENV, not $HOME
if [ -n $VIRTUAL_ENV]; then
    cd () {
        if (( $# == 0 ))
        then
            builtin cd $VIRTUAL_ENV
        else
            builtin cd "$@"
        fi
    }
fi

# VIM stuff
alias vis="vim -S .vim.session"
export EDITOR=vim

# Dotfiles in git
alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
unset GREP_OPTIONS
