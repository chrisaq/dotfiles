# echo sourcing $HOME/.zshenv

# zsh config files in the order they are sourced

# $ZDOTDIR/.zshenv
### sourced on all invocations of the shell
### contain commands to set the command search path
### should not contain commands that produce output or assume the shell is attached to a tty

# $ZDOTDIR/.zprofile
### meant as an alternative to .zlogin

# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.

# $ZDOTDIR/.zlogin
### is sourced in login shells. It should contain commands that should be executed only in login shells
### used to set the terminal type and run a series of external commands (fortune, msgs, etc).

# $ZDOTDIR/.zlogout
### sourced when login shells exit

# setting ZDOTDIR to .config/zsh stops ~/.zshrc from being sourced
ZDOTDIR=$HOME/.config/zsh
. $ZDOTDIR/.zshenv
