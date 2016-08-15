# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#
echo sourcing $HOME/.config/zsh/.zshrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# TODO Is this required anymore?
# Setting the TERM
if [ "$TERM" = "xterm" ] ; then
    if [ -z "$COLORTERM" ] ; then
        if [ -z "$XTERM_VERSION" ] ; then
            # echo "Warning: Terminal misidentifying itself 'xterm', assuming color term"
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


# Source zim
if [[ -s ${ZDOTDIR:-${HOME}}/.zim/init.zsh ]]; then
  source ${ZDOTDIR:-${HOME}}/.zim/init.zsh
fi

# Fonts:
# https://github.com/gabrielelana/awesome-terminal-fonts
# Prompt:
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k
# ln -s ~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k/powerlevel9k.zsh-theme ~/.config/zsh/.zim/modules/prompt/functions/prompt_powerlevel9k_setup
POWERLEVEL9K_INSTALLATION_PATH=~/.config/zsh/.zim/modules/prompt/external-themes/powerlevel9k/powerlevel9k.zsh-theme
#POWERLEVEL9K_MODE='awesome-fontconfig'
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv time)
POWERLEVEL9K_OS_ICON_BACKGROUND="white"
POWERLEVEL9K_OS_ICON_FOREGROUND="blue"
POWERLEVEL9K_DIR_HOME_FOREGROUND="white"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="white"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="white"
POWERLEVEL9K_MODE='awesome-patched'

# powerline
#if command -v powerline-daemon >/dev/null 2>&1; then
#    powerline-daemon -q
#fi
#PLDIR=/usr/lib/python3.5/site-packages/
#if [ -f "${PLDIR}/powerline/bindings/zsh/powerline.zsh" ]; then
#    . ${PLDIR}/powerline/bindings/zsh/powerline.zsh
#fi

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

