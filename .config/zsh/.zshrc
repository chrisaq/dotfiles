

#
# User configuration sourced by interactive shells
#
echo sourcing $HOME/.config/zsh/.zshrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Source zim
if [[ -s ${ZDOTDIR:-${HOME}}/.zim/init.zsh ]]; then
  source ${ZDOTDIR:-${HOME}}/.zim/init.zsh
fi

# powerline
if command -v powerline-daemon >/dev/null 2>&1; then
    powerline-daemon -q
fi

# Customize to your needs...
export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/srv/chains/bin:$HOME/.gem/ruby/2.2.0/bin:/opt/dropbox
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=1000
setopt appendhistory autocd notify
unsetopt beep

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# VIM stuff
alias vis="vim -S .vim.session"
export EDITOR=vim

# Dotfiles in git
alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
unset GREP_OPTIONS

# fasd
if command -v fasd >/dev/null 2>&1; then
    eval "$(fasd --init auto)"
fi

