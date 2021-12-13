# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#echo sourcing $HOME/.config/zsh/.zshrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export ZSHSTARTED=$(date +%Y%m%d%H%M%S)
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Download Znap, if it's not there yet.
[[ -f ${ZDOTDIR}/zsh-snap/znap.zsh ]] ||
    git clone https://github.com/marlonrichert/zsh-snap.git ${ZDOTDIR}/zsh-snap

source ${ZDOTDIR}/zsh-snap/znap.zsh  # Start Znap

### History
# fc -W  # <- try writing history to file, used to test for errors
HISTFILE=$XDG_CACHE_HOME/zsh-history
SAVEHIST=10000000
HISTSIZE=10000000
###################### Setopts
setopt extended_history
setopt inc_append_history_time # replaces sharehistory and inc_append_history
setopt hist_ignore_all_dups
setopt hist_no_functions
setopt hist_reduce_blanks
setopt autocd # writing the name of a directory moves shell into it
setopt notify
setopt interactive_comments
setopt list_types
setopt no_beep
setopt complete_in_word

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
alias cq_groups_refresh="exec sudo su -l $USER"

#reload zsh config
alias zshreload="source ${ZDOTDIR}/.zshrc"
alias cq_zshreload="source ${ZDOTDIR}/.zshrc"

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
export MBSYNCRC="$XDG_DATA_HOME"/isync/mbsyncrc
export KUBECONFIG="$XDG_CONFIG_HOME"/kube/config:"$XDG_CONFIG_HOME"/k0s/admin.conf
if [[ ! -d "$XDG_CONFIG_HOME"/kube ]]; then
    mkdir -p "$XDG_CONFIG_HOME"/kube
fi
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


# fzf (needs to come before plugins)
export FZF_ALT_C_COMMAND='fd --hidden --type d'
# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="fd --hidden --type f"
# trigger fzf on tab, not **
#export FZF_COMPLETION_TRIGGER=''

HAS_FZF=0 && command -v fzf >/dev/null 2>&1 && HAS_FZF=1
if [[ $HAS_FZF -eq 1  ]]; then
    fkill() {
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

        if [ "x$pid" != "x" ]; then
            kill -${1:-9} $pid
        fi
    }
fi

# zsh-autocomplete options
zstyle ':autocomplete:*' fzf-completion yes # enable fzf **<tab>
zstyle ':autocomplete:*' min-input 0

# path to user-installed ruby gems bin
if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
    PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# VIM stuff
# VI mode, breaks arrow history search
# bindkey -v
# emacs bindings
bindkey -e
export EDITOR=nvim

# Dotfiles in git
if [[ ! -d "$HOME"/.local/share/dotfiles.git ]]; then
    mkdir -p "$HOME"/.local/share/dotfiles.git
fi
alias dotfiles="git --git-dir=$HOME/.local/share/dotfiles.git/ --work-tree=$HOME"
if [[ ! -d "$HOME"/.local/share/dotlocal.git ]]; then
    mkdir -p "$HOME"/.local/share/dotlocal-$(hostnamectl --static).git
fi
alias dotlocal="git --work-tree=$HOME/ --git-dir=$HOME/.local/share/dotfiles-$(hostnamectl --static).git"
unset GREP_OPTIONS

alias pwdcopy='pwd | tr -d "\r\n" |xclip -selection clipboard'
alias copypwd="pwdcopy"

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

PassEdit() {
    pass=$(gopass ls --flat|fzf)
    gopass edit "$pass"
}

alias pass='gopass'
alias yubikey_reset_serial='rm ${GNUPGHOME}/private-keys-v1.d/{A7311DE4F14645F60A94FAB5A7864BDE48076BF4.key,C2BE7814190B272612D9E293BE85D9B670B76E50.key,F0B427412DD319186D0F26FB1E228AC93B4EA3BA.key} && gpgconf --kill gpg-agent && gpg --card-status'
# First pipe the selected name to gopass, encrypt it and type the password with xdotool.
alias PassMenux="gopass ls --flat | rofi -dmenu | xargs --no-run-if-empty gopass show -f | head -n 1 | xdotool type --clearmodifiers --file -"
alias xkcd_pwgen="gopass pwgen -x"

### ENDS: SEC section ##########################################################


####### MISC ALIASES
alias ls='ls --color=auto'

alias st="st -f 'Hack Nerd Font:style=Regular:pixelsize=16'"
alias stt="tabbed -c -r 2 st -w ''"
alias sysu='systemctl --user'
alias t="task"
# the () launches the command  in a subshell, not affecting CWD of shell running the alias.
alias skraper='(cd ~/bin/Skraper && mono SkraperUI.exe)'

alias git_get_all_branches='for abranch in $(git branch -a | grep -v HEAD | grep remotes | sed "s/remotes\/origin\///g"); do git checkout $abranch ; done'

## terraform, iac
alias tfinit='terraform init -backend-config=tf-init.conf'

# Helm
alias helm-completion='source <(helm completion zsh)'

# XRANDR, autorandr etc
alias cq-autorandr='autorandr $(autorandr | cut -d' ' -f1|rofi -dmenu)'

# Turns out the below is just an inconvenient version of fzf's ctrl-t
# ff: fd and fzy
# passes all args to command after ff, and then a file/dir as found by fzy at the end
# ex: "ff ls -l -a -d" results in the command ls -l -a -d <file/dir picked by fzy>
ff () {
    ffile=$(fd | fzy) && $1 "${@:2}" $ffile
}

completions-list () {
    for command completion in ${(kv)_comps:#-*(-|-,*)}
    do
        printf "%-32s %s\n" $command $completion
    done | sort
}

## terminfo
typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line

# disable software flow control, ctrl-s (XOFF)/ctrl-q (XON)
setopt noflowcontrol
# needs to be set this way or p10k instant prompt makes it print errors
stty -ixon <$TTY >$TTY

#znap config
zstyle ':znap:*' default-server 'git@github.com:'

znap clone \
     git@github.com:romkatv/powerlevel10k.git \
     git@github.com:zdharma-continuum/fast-syntax-highlighting \
     git@github.com:momo-lab/zsh-abbrev-alias.git \
     git@github.com:Aloxaf/fzf-tab.git \
     git@github.com:marlonrichert/{zsh-edit,zsh-hist}.git \
     trapd00r/LS_COLORS \
     ohmyzsh/ohmyzsh \
     git@github.com:zsh-users/{zsh-autosuggestions,zsh-history-substring-search,zsh-completions}.git \
     git@github.com:MichaelAquilina/zsh-you-should-use.git

znap source powerlevel10k
znap eval trapd00r/LS_COLORS "$( whence -a dircolors gdircolors ) -b LS_COLORS"
znap source fzf-tab
znap source ohmyzsh/ohmyzsh lib/{git,theme-and-appearance,completion}
znap source zsh-abbrev-alias
znap source zsh-you-should-use
znap source ohmyzsh/ohmyzsh plugins/{aws,direnv,docker-compose,fabric,fzf,git,helm,httpie,nmap,pip,python,sudo,systemd,taskwarrior,terraform}
if command -v kubectl>/dev/null 2>&1; then
    znap fpath _kubectl 'kubectl completion zsh'
if command -v k0s >/dev/null 2>&1; then
    znap fpath _k0s 'k0s completion zsh'
fi

# breaks when higher up for whatever reason
znap source fast-syntax-highlighting
znap source zsh-autosuggestions
znap source zsh-history-substring-search
znap source zsh-completions
# ENDS: breaks when higher up for whatever reason

#znap source marlonrichert/zcolors
#znap eval   marlonrichert/zcolors "zcolors ${(q)LS_COLORS}"

# TODO; powerlevel10k
# export ZSHSTARTED=$(date +%Y%m%d%H%M)
# test $(ls --time-style=+%Y%m%d -l $ZDOTDIR/.zshrc |cut -d' ' -f6) -lt $ZSHSTARTED && echo yes

#### HASH shortcuts
hash -d work=${HOME}/Sync/Work
hash -d ruter=${HOME}/Sync/Work/Ruter
hash -d wiki=${HOME}/Sync/Wiki
hash -d sync=${HOME}/Sync

# Powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
