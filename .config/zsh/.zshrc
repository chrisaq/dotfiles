# $ZDOTDIR/.zshrc
### debug section
# sourced in interactive shells. It should contain commands to set up aliases, functions, options, key bindings, etc.
#echo sourcing $HOME/.config/zsh/.zshrc

################################################################################
### Init zsh section
# If not running interactively, don't do anything
[ -z "$PS1" ] && return
export ZSHSTARTED=$(date +%Y%m%d%H%M%S)
### ENDS: zsh init #############################################################


################################################################################
### zsh-snap init section
zstyle ':znap:*' default-server 'git@github.com:'
# Download Znap, if it's not there yet.
[[ -f ${ZDOTDIR}/zsh-snap/znap.zsh ]] ||
    git clone https://github.com/marlonrichert/zsh-snap.git ${ZDOTDIR}/zsh-snap
# start zsh-snap
source ~/.config/zsh/zsh-snap/znap.zsh
#reload zsh config
alias zshreload="source ${ZDOTDIR}/.zshrc"
# alias cq_zshreload="source ${ZDOTDIR}/.zshrc"
alias cq_zshreload="znap restart"
### ENDS: zsh-snap init ########################################################


################################################################################
### Powerlevel10k section
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
### ENDS: Powerlevel10k ########################################################


################################################################################
### History section
# fc -W  # <- try writing history to file, used to test for errors
HISTFILE=$XDG_CACHE_HOME/zsh-history
SAVEHIST=10000000
HISTSIZE=10000000
### ENDS: History ##############################################################


################################################################################
### ZSH Options section
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
### ENDS: zsh options ##########################################################


################################################################################
### XDG section
# should be set by pam, but missing in some places
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_BIN_HOME=${HOME}/.local/bin
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_RUNTIME_DIR=/run/user/`id -u`
# Setting this breaks seahorse and perhaps others:
# export XDG_DATA_DIRS=""
# because xdg-utils are(were?) broken:
export DE="generic"
##### XDG apps workarounds #####
# https://wiki.archlinux.org/index.php/XDG_Base_Directory_support
# TODO: .xinitrc, ~/.Xresources ~/.Xdefaults
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
export GOPATH="$XDG_DATA_HOME"/go
export TASKDATA="$XDG_DATA_HOME"/task
export TASKRC="$XDG_CONFIG_HOME"/task/taskrc
export MBSYNCRC="$XDG_DATA_HOME"/isync/mbsyncrc
export KUBECONFIG="$XDG_CONFIG_HOME"/kube/config
# if [[ -f  "$XDG_CONFIG_HOME"/k3s/k3s-home.yaml ]]; then
#     export KUBECONFIG=$KUBECONFIG:"$XDG_CONFIG_HOME"/k3s/k3s-home.yaml
# fi
# if [[ -f  "$XDG_CONFIG_HOME"/k0s/admin.conf ]]; then
#     export KUBECONFIG=$KUBECONFIG:"$XDG_CONFIG_HOME"/k0s/admin.conf
# fi
if [[ ! -d "$XDG_CONFIG_HOME"/kube ]]; then
    mkdir -p "$XDG_CONFIG_HOME"/kube
fi
if [[ ! -d "$XDG_DATA_HOME"/pyenv ]]; then
    mkdir -p "$XDG_DATA_HOME"/pyenv
fi
export PYENV_ROOT="${XDG_DATA_HOME}/pyenv"
# disable shared library build for pyenv
export PYTHON_CONFIGURE_OPTS="--disable-shared"
export PYTHONSTARTUP="$XDG_CONFIG_HOME"/python/pythonrc
# asdf config location
export ASDF_DATA_DIR="${XDG_DATA_HOME:-~./local/share}/asdf"
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME:-~./config}/asdf/asdfrc"
# export ASDF_DIR="${XDG_CONFIG_HOME}/asdf/"
# TODO: temp disable
#export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
#export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config
# XDG: using aliases as workarounds
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
alias weechat='weechat -d "$XDG_CONFIG_HOME"/weechat'
export CARGO_HOME="$XDG_DATA_HOME"/cargo
### ENDS: XDG ##################################################################


################################################################################
### PATH section
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
# NODEJS version manager
[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh
### ENDS: PATH #################################################################


################################################################################
### less and lessfilter section
export LESSOPEN='| ${HOME}/.local/bin/lessfilter %s'
# export LESSOPEN='| ${HOME}/.config/zsh/fzf-zsh-plugin/bin/lessfilter-fzf %s'
export LESS=' -R '
alias noless='LESSOPEN= less' # less without lessfilter
compdef noless=less # use same completion
# Helper function to get filetype and kind from file for use in lessfilter
lessfilter_vars() {
  local filename="$1"
  local ext=$(basename "${filename##*.}")
  echo "category: ${$(file -Lbs --mime-type $1)%%/*}"
  echo "kind: ${$(file -Lbs --mime-type ${filename})##*/}"
  echo "ext: $ext"
}
export MDCAT_PAGER='less --pattern=^┄(┄|)'
### ENDS: less and lessfilter ##################################################


################################################################################
### GPG section
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
### ENDS: GPG ##################################################################


################################################################################
### FZF section
export FZF_COMMON_OPTIONS="
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --bind='insert:toggle+down,delete:deselect+down'
  --preview-window 'right:60%::wrap'"
#   # --preview-window 'right:60%:hidden:wrap'
#   # --preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"
export FZF_EXCLUDES="--exclude .git --exclude node_modules --exclude '.mozilla' --exclude '.cache'"
# export FZF_PREVIEW_COMMAND="bat --style=numbers,changes \
#     --wrap never --color always {} || cat {} || tree -C {}"
# export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow ${FZF_EXCLUDES}"
export FZF_DEFAULT_OPTS="$FZF_COMMON_OPTIONS"
# # fzf commands
export FZF_ALT_C_COMMAND="fd --hidden --one-file-system --type d ${FZF_EXCLUDES}"
# export FZF_ALT_C_OPTS=""
export FZF_CTRL_T_COMMAND="fd --hidden --one-file-system --type f ${FZF_EXCLUDES}"
# export FZF_CTRL_T_OPTS=" \
#     $FZF_COMMON_OPTIONS \
#     --preview '($FZF_PREVIEW_COMMAND)' \
#     --height 60% --border sharp \
#     --layout reverse --prompt '∷ ' --pointer ▶ --marker ⇒ "
#
export FZF_PATH=${HOME}/.config/zsh/fzf
#
HAS_FZF=0 && command -v fzf >/dev/null 2>&1 && HAS_FZF=1
if [[ $HAS_FZF -eq 1  ]]; then
    fkill() {
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
        if [ "x$pid" != "x" ]; then
            kill -${1:-9} $pid
        fi
    }
fi
# _fzf_comprun() {
#   local command=$1
#   shift
#
#   case "$command" in
#     cd)           fzf ---preview-window 'right:60%::wrap ' --preview 'exa -1 --color=always $realpath'   "$@" ;;
#     ls)           fzf ---preview-window 'right:60%::wrap ' --preview 'exa -1 --color=always $realpath'   "$@" ;;
#     export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
#     ssh)          fzf --preview 'dig {}'                   "$@" ;;
#     *)            fzf --preview-window 'right:60%:hidden:wrap' --preview "bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}" "$@" ;;
#   esac
#     # *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
# }
# zsh-autocomplete options
zstyle ':autocomplete:*' fzf-completion yes # enable fzf **<tab>
zstyle ':autocomplete:*' min-input 0
### ENDS: FZF ##################################################################


################################################################################
### FZF-TAB section
# fzf-tab recommended config
# # disable sort when completing `git checkout`
# zstyle ':completion:*:git-checkout:*' sort false
# # set descriptions format to enable group support
# zstyle ':completion:*:descriptions' format '[%d]'
# # set list-colors to enable filename colorizing
# zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# # switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
# set insert/delete to toggle/deselect multiple items
zstyle ':fzf-tab:*' fzf-bindings 'insert:toggle+down,delete:deselect+down'
# # preview directory's content with exa when completing cd
#zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath' # remember to use single quote here!!!
# TODO:  testing
# zstyle ':fzf-tab:complete:*:*' fzf-preview '${XDG_BIN_HOME}/lessfilter ${(Q)realpath}'
# testing ends
# zstyle ':fzf-tab:complete:*:*' fzf-preview 'less -e +G ${(Q)realpath}'
# Do not show preview for options
zstyle ':fzf-tab:complete:*:options' fzf-preview ''
# Do not show preview for arguments (TODO: not working?)
zstyle ':fzf-tab:complete:*:argument-1' fzf-preview ''
### ENDS: FZF-TAB ##############################################################


################################################################################
### Input section
# vi mode
bindkey -v
# Bind up arrow to history-beginning-search-backward in insert mode
bindkey '^[[A' history-beginning-search-backward
# Bind down arrow to history-beginning-search-forward in insert mode
bindkey '^[[B' history-beginning-search-forward
# Bind arrow keys in normal mode
bindkey -M vicmd '^[[A' history-beginning-search-backward
bindkey -M vicmd '^[[B' history-beginning-search-forward
# emacs mode
# bindkey -e
export EDITOR=nvim
# PAGER
export PAGER=bat
### ENDS: Input ################################################################


################################################################################
### git section
alias gcassm='git commit --gpg-sign --signoff -a --message'
alias gdf='git diff --color | diff-so-fancy'
alias git_get_all_branches='for abranch in $(git branch -a | grep -v HEAD | grep remotes | sed "s/remotes\/origin\///g"); do git checkout $abranch ; done'
### ENDS: git ##################################################################


################################################################################
### Dotfiles section
if [[ ! -d "$HOME"/.local/share/dotfiles.git ]]; then
    mkdir -p "$HOME"/.local/share/dotfiles.git
fi
alias dotfiles="git --git-dir=$HOME/.local/share/dotfiles.git/ --work-tree=$HOME"
alias dcassm='dotfiles commit --all --gpg-sign --signoff --message'
compdef dotfiles=git # use same completion for dotfiles as git
alias dtig="GIT_DIR=$XDG_DATA_HOME/dotfiles.git GIT_WORK_TREE=${HOME} tig"
alias dlazygit="lazygit --git-dir=$XDG_DATA_HOME/dotfiles.git/ --work-tree=$HOME"
# dotfiles based on hostname (per-machine dotfiles)
if [[ ! -d "$HOME"/.local/share/dotlocal.git ]]; then
    mkdir -p "$HOME"/.local/share/dotlocal-$(hostnamectl --static).git
fi
alias dotlocal="git --work-tree=$HOME/ --git-dir=$HOME/.local/share/dotfiles-$(hostnamectl --static).git"
alias lcassm='dotlocal commit --all --gpg-sign --signoff --message'
compdef dotlocal=git # use same completion for dotlocal as git
alias ltig="GIT_DIR=${XDG_DATA_HOME}/dotfiles-$(hostnamectl --static).git GIT_WORK_TREE=${HOME} tig"
alias llazygit="lazygit --git-dir=$XDG_DATA_HOME/dotfiles.git/ --work-tree=$HOME"
unset GREP_OPTIONS
### ENDS: Dotfiles #############################################################


################################################################################
### Security section - gpg, yubikey, pass, gopass, password-store etc
# gpg
# restart gpg-agent on new tty
alias gpg-tty-update="gpg-connect-agent UPDATESTARTUPTTY /bye >/dev/null"
#
# #if [[ -s ${ZDOTDIR:-${HOME}}/gpg-agent.plugin.zsh ]]; then
# #  source ${ZDOTDIR:-${HOME}}/gpg-agent.plugin.zsh
# #fi
#
export PASSWORD_STORE_DIR=$HOME/Sync/Password-Store
# pass with fuzzy search
Pass() {
    pass=$(gopass ls -f | fzf +m) && \
    gopass -c "$pass"
}
# pass edit with fuzzy search
PassEdit() {
    pass=$(gopass ls --flat|fzf)
    gopass edit "$pass"
}
# make all pass aliases work
alias pass='gopass'
alias yubikey_reset_serial='rm ${GNUPGHOME}/private-keys-v1.d/{A7311DE4F14645F60A94FAB5A7864BDE48076BF4.key,C2BE7814190B272612D9E293BE85D9B670B76E50.key,F0B427412DD319186D0F26FB1E228AC93B4EA3BA.key} && gpgconf --kill gpg-agent && gpg --card-status'
# First pipe the selected name to gopass, encrypt it and type the password with xdotool.
alias PassMenux="gopass ls --flat | rofi -dmenu | xargs --no-run-if-empty gopass show -f | head -n 1 | xdotool type --clearmodifiers --file -"
alias xkcd_pwgen="gopass pwgen -x --lang en --sep ' ' 5"
# decrypt two files and send them to diff/meld
# used for syncthing conflicts in crypt-sync files
function cq_decrypt_diff() {
  local program="$1"
  local file1="$2"
  local file2="$3"
  shift 3
  "$program" <(gpg --quiet --decrypt "$file1") <(gpg --quiet --decrypt "$file2") "$@"
}
_cq_decrypt_diff_completions() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  _arguments -C \
    '1: :_command_names' \
    '2: :_files' \
    '3: :_files'
}
compdef _decrypt_and_run_completions decrypt_and_run
### ENDS: Security #############################################################


################################################################################
### Aliases and functions section
# update shell to include recently created group(s)
alias cq_groups_refresh="exec sudo su -l $USER"
alias pwdcopy='pwd | tr -d "\r\n" |xclip -selection clipboard'
alias copypwd="pwdcopy"
# prints 256 color palette
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
# redirect sudo to append to file
cq_sudo_append() {
    local file="$1"
    shift
    local text="$*"
    echo "$text" | sudo tee -a "$file" > /dev/null
}
# send command to all tmux sessions
tmux_command_to_all() {
    for session in `tmux list-sessions -F '#S'`; do
        for window in `tmux list-windows -t $session -F '#P' | sort`; do
            for pane in `tmux list-panes -t $session:$window -F '#P' | sort`; do
                tmux send-keys -t "$session:$window.$pane" "$*" C-m
            done
        done
    done
}
# prints true color palette
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
# exa aliases
compdef eza=ls # use same completion
alias xl="eza --group-directories-first --classify --git --icons"
alias xll="xl -l"
alias lx="eza --group-directories-first --classify --git --icons"
alias lxx="xl -l"
# alias ls='ls --color=auto'
alias mouseslow='xinput --set-prop $(xinput list | grep "Razer Razer Orochi" | grep -vi keyboard| cut -d '=' -f2 | cut -f1) "libinput Accel Speed" -1'
alias cqmouseslow2='xinput --set-prop $(xinput list | grep "Razer Razer Orochi" | grep -vi keyboard| cut -d '=' -f2 | cut -f1) "libinput Accel Speed" -1'
alias cqmouseslow='xinput --set-prop $(xinput list | grep "Razer Razer Orochi" | grep -vi keyboard| cut -d '=' -f2 | cut -f1) "Coordinate Transformation Matrix" 0.5 0 0 0 0.5 0 0 0 1'
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
alias cq_snd_restart="systemctl --user restart pipewire pipewire-pulse wireplumber"
alias tfinit='terraform init -backend-config=tf-init.conf'
alias helm-completion='source <(helm completion zsh)'
# swap workspaces 1 and 2
# make this a script for use in i3
function cq_autorandr() {
    autorandr $(autorandr | cut -d' ' -f1|rofi -dmenu)
}
function i3_swap() {
    i3-msg "rename workspace $1 to temporary;
            rename workspace $2 to $1;
            rename workspace temporary to $2"
}
# start tmux sessions
function cqtmux_startup() {
    if ! tmux has-session -t "001-Main" 2>/dev/null; then
        tmux new-session -d -s 001-Main -c ~/
    fi
    if ! tmux has-session -t "002-Docs" 2>/dev/null; then
        tmux new-session -d -s 002-Docs -c ~/Sync/Wiki
    fi
    if ! tmux has-session -t "003-Mail" 2>/dev/null; then
        tmux new-session -d -s 003-Mail -c ~/Sync/EmailAttachments
    fi
    if ! tmux has-session -t "004-Chains" 2>/dev/null; then
        tmux new-session -d -s 004-Chains -c ~/Code/chains2
    fi
    if ! tmux has-session -t "100-Work" 2>/dev/null; then
        tmux new-session -d -s 100-Work -c ~/Code/Ruter
    fi
    if ! tmux has-session -t "101-K8S" 2>/dev/null; then
        tmux new-session -d -s 101-K8S -c ~/Code/Ruter/K8S-UPGRADE-REPOS
    fi
}
cq-completions-list () {
    for command completion in ${(kv)_comps:#-*(-|-,*)}
    do
        printf "%-32s %s\n" $command $completion
    done | sort
}
# what package does a binary belong to
function pacwhich() {pacman -Qo $(which $1 )}
# Install paru
function cq_paru_install() {
    if ! command -v git >/dev/null 2>&1; then
        sudo pacman -S git
    fi
    mkdir -p ~/tmp/
    git clone https://aur.archlinux.org/paru.git
    cd ~/tmp/paru
    makepkg -si
}
# Set env from KEY=value list in file
cq_env_arg() {set -o allexport; source $@; set +o allexport}
cq_env_select() {set -o allexport; source $(fd .conf ~/.config/env -t f|fzf); set +o allexport}
# Run command with env from ./.env
cq_with_env() {
    (set -a && . ./.env && "$@")
}
# neovim / vim aliases
# Notes: nvim instance - notes in vim, persistence and such
alias cqnote="nvim -u $XDG_CONFIG_HOME/nvim-configs/cqnote/init.lua $HOME/Sync/Wiki/Tech/Tech/QuickNote.md"
alias cqnote-init="cqnote --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'"
# Install nvim configuration from scratch:
# nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
# Separate nvim configs example:
# alias cqnvim="nvim -u $XDG_CONFIG_HOME/cqnvim/init.lua"
cq_nvim_create() {
    local config_name=$1
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim-configs"
    local config_path="$config_dir/$config_name"
    local template_file="${XDG_CONFIG_HOME:-$HOME/.config}/nvim-configs/init.lua.template"
    if [ -z "$config_name" ]; then
        echo "Usage: cq_nvim_create <config_name>"
        return 1
    fi
    # Check if the template file exists
    if [ ! -f "$template_file" ]; then
        echo "Template file $template_file not found. Please create one."
        return 1
    fi
    # Create the configuration directory
    if [ -d "$config_path" ]; then
        echo "Configuration $config_name already exists."
        return 1
    fi
    mkdir -p "$config_path"/lua/user/plugins
    echo "-- nvim options go here" >> "$config_path/lua/user/options.lua"
    echo "-- plugins in this file or directory will be automatically loaded." >> "$config_path/lua/user/plugins/init.lua"
    echo "return {}" >> "$config_path/lua/user/plugins/init.lua"
    cp "$template_file" "$config_path/init.lua"
    echo "Created Neovim configuration: $config_dir"
    echo "Copied template to: $config_dir/init.lua"
    # Print the zsh function to be added to .zshrc
    echo "\nTo add this config, add the following function to your .zshrc:"
    echo "-----------------------------------------------"
    cat << EOF
nvim_$config_name() {
    NVIM_APPNAME="nvim-configs/$config_name" nvim "\$@"
}
EOF
    echo "-----------------------------------------------"
}

#
# k8s aliases and functions
function cq_eks_drain_nodes() {
  if [ "$#" -eq 0 ]; then
    echo "Usage: terminate_nodes <node1> <node2> ... <nodeN>"
    return 1
  fi
  for node in "$@"; do
    echo "Processing node: $node"
    # Cordon the node
    echo "Cordoning node $node..."
    kubectl cordon "$node"
    if [ $? -ne 0 ]; then
      echo "Failed to cordon node $node"
      continue
    fi
    # Drain the node
    echo "Draining node $node..."
    kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force
    if [ $? -ne 0 ]; then
      echo "Failed to drain node $node"
      continue
    fi
    # Get the EC2 instance ID from the node's Kubernetes annotation
    instance_id=$(kubectl get node "$node" -o jsonpath='{.spec.providerID}' | cut -d '/' -f5)
    if [ -z "$instance_id" ]; then
      echo "Failed to get EC2 instance ID for node $node"
      continue
    fi
    # Terminate the EC2 instance
    echo "Terminating EC2 instance $instance_id for node $node..."
    aws ec2 terminate-instances --instance-ids "$instance_id"
    if [ $? -ne 0 ]; then
      echo "Failed to terminate EC2 instance $instance_id for node $node"
      continue
    fi
    echo "Node $node successfully cordoned, drained, and EC2 instance $instance_id terminated."
  done
}
### ENDS: Aliases and functions ################################################

################################################################################
## terminfo section
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
### ENDS: terminfo #############################################################


################################################################################
### zsh-snap section
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
znap source ohmyzsh/ohmyzsh plugins/{aws,direnv,docker-compose,fabric,git,nmap,pip,pyenv,python,sudo,systemd,taskwarrior,terraform}
# znap source ohmyzsh/ohmyzsh plugins/{globalias} # automatically expand aliases
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
### ENDS: zsh-snap #############################################################


################################################################################
### Override section - override keybindings and such from modules and tools above
## TMSTART
# binding a shell script to a ctrl sequence needs a function to work
tmstart() {
    $HOME/.local/bin/tmstart
}
# Then make the function a zsh widget:
zle -N tmstart
bindkey '^S' tmstart
## expand aliases using tab right after the alias:
bindkey "^Xa" _expand_alias
zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' regular true
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
### ENDS: Override #############################################################
