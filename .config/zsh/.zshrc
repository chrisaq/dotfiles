# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#
#echo sourcing $HOME/.config/zsh/.zshrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# this shouldn't be forced here
#export TERM="xterm-256color"

# Fonts:
# https://github.com/gabrielelana/awesome-terminal-fonts
# Prompt:
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k
# ln -s ~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k/powerlevel9k.zsh-theme ~/.config/zsh/.zim/modules/prompt/functions/prompt_powerlevel9k_setup
POWERLEVEL9K_INSTALLATION_PATH=~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k/powerlevel9k.zsh-theme
POWERLEVEL9K_MODE='awesome-fontconfig'
#POWERLEVEL9K_MODE='awesome-patched'
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv time)
POWERLEVEL9K_DIR_HOME_FOREGROUND="white"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="white"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="white"
#POWERLEVEL9K_VI_INSERT_MODE_STRING="INS"
#POWERLEVEL9K_VI_COMMAND_MODE_STRING="CMD"

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
    PATH="$(ruby -rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi


# VI mode, breaks arrow history search
# bindkey -v
# VIM stuff
alias vis="vim -S .vim.session"
export EDITOR=vim

# Dotfiles in git
alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
unset GREP_OPTIONS

# fzf
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

