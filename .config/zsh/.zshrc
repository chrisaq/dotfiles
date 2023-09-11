# $ZDOTDIR/.zshrc
### sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#echo sourcing $HOME/.config/zsh/.zshrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

zstyle ':znap:*' default-server 'git@github.com:'
# Download Znap, if it's not there yet.
[[ -f ${ZDOTDIR}/zsh-snap/znap.zsh ]] ||
    git clone https://github.com/marlonrichert/zsh-snap.git ${ZDOTDIR}/zsh-snap

source ~/.config/zsh/zsh-snap/znap.zsh

export ZSHSTARTED=$(date +%Y%m%d%H%M%S)
#
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


### History
# fc -W  # <- try writing history to file, used to test for errors
HISTFILE=$XDG_CACHE_HOME/zsh-history
SAVEHIST=10000000
HISTSIZE=10000000

# # testing Manual history search
# up-line-or-history-beginning-search () {
#   if [[ -n $PREBUFFER ]]; then
#     zle up-line-or-history
#   else
#     zle history-beginning-search-backward
#   fi
# }
# zle -N up-line-or-history-beginning-search
#
###################### Setopts
setopt extended_history
setopt inc_append_history_time # replaces sharehistory and inc_append_history
setopt hist_ignore_dups # do not write dups if same as previous command
setopt hist_ignore_space # do not write command to history if it starts with a space
setopt hist_reduce_blanks
# setopt hist_ignore_all_dups # do not write any dups to history, delete previous entry
# setopt hist_no_functions # do not write functions to history
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

# snap
if [ -d "/var/lib/snapd/snap/bin" ] ; then
    PATH="$PATH:/var/lib/snapd/snap/bin"
fi

# perl
if [ -d "/usr/bin/vendor_perl/" ] ; then
    PATH="$PATH:/usr/bin/vendor_perl"
fi


# update shell to include recently created group(s)
alias cq_groups_refresh="exec sudo su -l $USER"

#reload zsh config
alias zshreload="source ${ZDOTDIR}/.zshrc"
# alias cq_zshreload="source ${ZDOTDIR}/.zshrc"
alias cq_zshreload="znap restart"

# lower mouse accel

#####  XDG stuff #####
# should be set by pam, but missing in some places
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_BIN_HOME=${HOME}/.local/bin
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_RUNTIME_DIR=/run/user/`id -u`
# Setting this breaks seahorse and perhaps others:
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
export KUBECONFIG="$XDG_CONFIG_HOME"/kube/config
if [[ -f  "$XDG_CONFIG_HOME"/kube/k3s-home.yaml ]]; then
    export KUBECONFIG=$KUBECONFIG:"$XDG_CONFIG_HOME"/kube/k3s-home.yaml
fi
if [[ -f  "$XDG_CONFIG_HOME"/k0s/admin.conf ]]; then
    export KUBECONFIG=$KUBECONFIG:"$XDG_CONFIG_HOME"/k0s/admin.conf
fi
if [[ ! -d "$XDG_CONFIG_HOME"/kube ]]; then
    mkdir -p "$XDG_CONFIG_HOME"/kube
fi
if [[ ! -d "$XDG_DATA_HOME"/pyenv ]]; then
    mkdir -p "$XDG_DATA_HOME"/pyenv
fi
export PYENV_ROOT="${XDG_DATA_HOME}/pyenv"
# disable shared library build for pyenv
export PYTHON_CONFIGURE_OPTS="--disable-shared"

export ASDF_DATA_DIR="${XDG_DATA_HOME:-~./local/share}/asdf"
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME:-~./config}/asdf/asdfrc"
# export ASDF_DIR="${XDG_CONFIG_HOME}/asdf/"

# temp disable
#export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
#export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config

##### XDG using aliases as workarounds
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
alias weechat='weechat -d "$XDG_CONFIG_HOME"/weechat'

### LESS
export LESSOPEN='| ${HOME}/.config/less/lessfilter %s'
export LESS=' -R '
# export LESSOPEN='| ${HOME}/.config/zsh/fzf-zsh-plugin/bin/lessfilter-fzf %s'

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


export MDCAT_PAGER='less --pattern=^┄(┄|)'

# fzf - `?` for file preview, `.`, 
export FZF_COMMON_OPTIONS="
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --preview-window 'right:60%:hidden:wrap'
  --preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"
  export FZF_EXCLUDES="--exclude .git --exclude node_modules --exclude '.mozilla' --exclude '.cache'"
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes \
    --wrap never --color always {} || cat {} || tree -C {}"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow ${FZF_EXCLUDES}"
export FZF_DEFAULT_OPTS="$FZF_COMMON_OPTIONS"
# fzf commands
export FZF_ALT_C_COMMAND="fd --hidden --one-file-system --type d ${FZF_EXCLUDES}"
export FZF_ALT_C_OPTS=""
export FZF_CTRL_T_COMMAND="fd --hidden --one-file-system --type f ${FZF_EXCLUDES}"
export FZF_CTRL_T_OPTS=" \
    $FZF_COMMON_OPTIONS \
    --preview '($FZF_PREVIEW_COMMAND)' \
    --height 60% --border sharp \
    --layout reverse --prompt '∷ ' --pointer ▶ --marker ⇒ "

export FZF_PATH=${HOME}/.config/zsh/fzf

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

# fzf-tab recommended config
# # disable sort when completing `git checkout`
# zstyle ':completion:*:git-checkout:*' sort false
# # set descriptions format to enable group support
# zstyle ':completion:*:descriptions' format '[%d]'
# # set list-colors to enable filename colorizing
# zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# # preview directory's content with exa when completing cd
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# # switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath' # remember to use single quote here!!!
zstyle ':fzf-tab:complete:*:*' fzf-preview '${XDG_BIN_HOME}/lessfilter ${(Q)realpath}'
# zstyle ':fzf-tab:complete:*:*' fzf-preview 'less -e +G ${(Q)realpath}'
# zstyle ':fzf-tab:complete:*:*' fzf-preview 'less /home/chrisq/Sync/Memes/unsorted/98-dd9492-1928-4-d93-90-c4-c3-ade727-ce53-618x447.jpg' # remember to use single quote here!!!

# path to user-installed ruby gems bin
if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
    PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# pyenv / pipx
if command -v pyenv >/dev/null 2>&1; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    export PIPX_DEFAULT_PYTHON=$(which python)
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
    compdef dotfiles=git # use same completion for dotfiles as git
if [[ ! -d "$HOME"/.local/share/dotlocal.git ]]; then
    mkdir -p "$HOME"/.local/share/dotlocal-$(hostnamectl --static).git
fi
alias dotlocal="git --work-tree=$HOME/ --git-dir=$HOME/.local/share/dotfiles-$(hostnamectl --static).git"
compdef dotlocal=git # use same completion for dotfiles as git
unset GREP_OPTIONS

alias pwdcopy='pwd | tr -d "\r\n" |xclip -selection clipboard'
alias copypwd="pwdcopy"

256color() {
    for k in `seq 0 1`;do
        for j in `seq $((16+k*18)) 36 $((196+k*18))`;do
            for i in `seq $j $((j+17))`; do
                printf "\e[01;$1;38;5;%sm%4s" $i $i;
            done;echo;
        done;
    done; echo
    for i in {234..255}; do printf "\e[01;$1;38;5;%sm%4s" $i  $i; done; echo
}

truecolor() {
    awk 'BEGIN{
        s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
        for (colnum = 0; colnum<77; colnum++) {
            r = 255-(colnum*255/76);
            g = (colnum*510/76);
            b = (colnum*255/76);
            if (g>255) g = 510-g;
            printf "\033[48;2;%d;%d;%dm", r,g,b;
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
            printf "%s\033[0m", substr(s,colnum+1,1);
        }
        printf "\n";
    }'
}

alias xl="exa --group-directories-first --classify --git"
alias xll="xl -l"
export SKIM_DEFAULT_COMMAND="rg --files || find ."
alias skvi='f(){ x="$(sk --bind "ctrl-p:toggle-preview" --ansi --preview="preview.sh -v {}" --preview-window=up:50%:hidden)"; [[ $? -eq 0 ]] && nvim "$x" || true }; f'
alias rgvi='f(){ x="$(sk --bind "ctrl-p:toggle-preview" --ansi -i -c "rg --color=always --line-number \"{}\"" --preview="preview.sh -v {}" --preview-window=up:50%:hidden)"; [[ $? -eq 0 ]] && nvim "$(echo $x|cut -d: -f1)" "+$(echo $x|cut -d: -f2)" || true }; f'

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
alias mouseslow='xinput --set-prop $(xinput list | grep "Razer Razer Orochi" | grep -vi keyboard| cut -d '=' -f2 | cut -f1) "libinput Accel Speed" -1'
alias cqmouseslow='xinput --set-prop $(xinput list | grep "Razer Razer Orochi" | grep -vi keyboard| cut -d '=' -f2 | cut -f1) "libinput Accel Speed" -1'
alias hiddenfiles='ls -d .*'
alias cqhiddenfiles='ls -d .*'
alias crypt-sync="${HOME}/bin/crypt-sync/crypt-sync.sh"
alias pysu='sudo $(printenv VIRTUAL_ENV)/bin/python'
alias pyvenvsu='sudo $(printenv VIRTUAL_ENV)/bin/python'
alias pysu2='sudo $(printenv VIRTUAL_ENV)/bin/python2'
alias pysu3='sudo $(printenv VIRTUAL_ENV)/bin/python3'
alias st="st -f 'Hack Nerd Font:style=Regular:pixelsize=16'"
alias stt="tabbed -c -r 2 st -w ''"
alias sysu='systemctl --user'
alias josu='journalctl --user'
alias t="task"
# the () launches the command  in a subshell, not affecting CWD of shell running the alias.
alias skraper='(cd ~/bin/Skraper && mono SkraperUI.exe)'
alias i3_swap_1and2='i3-msg "rename workspace 1 to temporary; rename workspace 2 to 1; rename workspace temporary to 2"'
alias spotify-ncspot='ncspot'
alias spotify-spotube='spotube'
alias spotify-tui='spt'
alias spotify-psst='psst'

function i3_swap() {
    i3-msg "rename workspace $1 to temporary;
            rename workspace $2 to $1;
            rename workspace temporary to $2"
}

alias git_get_all_branches='for abranch in $(git branch -a | grep -v HEAD | grep remotes | sed "s/remotes\/origin\///g"); do git checkout $abranch ; done'

## terraform, iac
alias tfinit='terraform init -backend-config=tf-init.conf'

# Helm
alias helm-completion='source <(helm completion zsh)'

# NODEJS
[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh

# XRANDR, autorandr etc
# make this a script
# alias cq-autorandr="autorandr $(autorandr | cut -d' ' -f1|rofi -dmenu)"

# NeoVim / vim aliases
# Notes in vim, persistence and such
alias cqnote="nvim -u $XDG_CONFIG_HOME/nvim-configs/cqnote/init.lua $HOME/Sync/Wiki/Tech/docs/QuickNote.md"
alias cqnote-init="cqnote --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'"
# Install nvim configuration from scratch:
# nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
# Separate nvim configs example:
# alias cqnvim="nvim -u $XDG_CONFIG_HOME/cqnvim/init.lua"

# Turns out the below is just an inconvenient version of fzf's ctrl-t
# ff: fd and fzy
# passes all args to command after ff, and then a file/dir as found by fzy at the end
# ex: "ff ls -l -a -d" results in the command ls -l -a -d <file/dir picked by fzy>
ff () {
    ffile=$(fd | fzy) && $1 "${@:2}" $ffile
}

cq-completions-list () {
    for command completion in ${(kv)_comps:#-*(-|-,*)}
    do
        printf "%-32s %s\n" $command $completion
    done | sort
}

# what package does a binary belong to
function pacwhich() {pacman -Qo $(which $1 )}

# Set env from KEY=value list in file
cq_env_arg() {set -o allexport; source $@; set +o allexport}
cq_env_select() {set -o allexport; source $(fd .conf ~/.config/env -t f|fzf); set +o allexport}

# Run command with env from ./.env
cq_with_env() {
    (set -a && . ./.env && "$@")
}
## terminfo
typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line

# Needs to be below terminfo stuff above
# arrow-up/down partial match search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down


# disable software flow control, ctrl-s (XOFF)/ctrl-q (XON)
setopt noflowcontrol
# needs to be set this way or p10k instant prompt makes it print errors
stty -ixon <$TTY >$TTY

#znap config
znap clone \
     git@github.com:romkatv/powerlevel10k.git \
     git@github.com:zdharma-continuum/fast-syntax-highlighting \
     git@github.com:chrisaq/zsh-abbrev-alias.git \
     git@github.com:junegunn/fzf.git \
     trapd00r/LS_COLORS \
     ohmyzsh/ohmyzsh \
     git@github.com:zsh-users/{zsh-autosuggestions,zsh-completions}.git \
     git@github.com:Aloxaf/fzf-tab.git \
     git@github.com:Freed-Wu/fzf-tab-source.git \
     git@github.com:MichaelAquilina/zsh-you-should-use.git
#     git@github.com:unixorn/fzf-zsh-plugin.git \
     # git@github.com:zsh-users/{zsh-autosuggestions,zsh-history-substring-search,zsh-completions}.git \
     # git@github.com:momo-lab/zsh-abbrev-alias.git \

znap source powerlevel10k
znap eval trapd00r/LS_COLORS "$( whence -a dircolors gdircolors ) -b LS_COLORS"
znap source junegunn/fzf shell/{completion,key-bindings}.zsh
# fzf-tab before plugins which will wrap widgets 
# such as zsh-autosuggestions or fast-syntax-highlighting
znap source fzf-tab
znap source fzf-tab-source
znap source ohmyzsh/ohmyzsh lib/{git,theme-and-appearance,completion}
znap source zsh-you-should-use
znap source zsh-abbrev-alias
znap source ohmyzsh/ohmyzsh plugins/{globalias,aws,direnv,docker-compose,fabric,git,nmap,pip,pyenv,python,sudo,systemd,taskwarrior,terraform}
if command -v kubectl >/dev/null 2>&1; then
    znap fpath _kubectl 'kubectl completion zsh'
fi
if command -v k0s >/dev/null 2>&1; then
    znap fpath _k0s 'k0s completion zsh'
fi

# breaks when higher up for whatever reason
znap source fast-syntax-highlighting
ZSH_AUTOSUGGEST_STRATEGY=( history )
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan,bg=bold,underline"
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=red,bg=grey,bold,underline"
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"
znap source zsh-autosuggestions
# znap source zsh-history-substring-search
znap source zsh-completions
znap source asdf-vm/asdf
# ENDS: breaks when higher up for whatever reason

#### HASH shortcuts
hash -d code=${HOME}/Code
hash -d work=${HOME}/Sync/Work
hash -d ruter=${HOME}/Sync/Work/Ruter
hash -d wiki=${HOME}/Sync/Wiki
hash -d sync=${HOME}/Sync

#### abbrev
function Q() {
    qcmd=$(compgen -c | grep '^cq' | fzf)
    $qcmd
}
abbrev-alias -g G="| rg"

# Powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
