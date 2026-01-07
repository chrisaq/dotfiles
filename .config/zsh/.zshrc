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
# grep with catppuccin macchiato for grep/ugrep
export GREP_COLORS='mt=38;5;177:fn=38;5;110:ln=38;5;246'
export LESSKEY="$XDG_CONFIG_HOME"/less/lesskey
export MEDNAFEN_HOME="$XDG_CONFIG_HOME"/mednafen
export NOTMUCH_CONFIG="$XDG_CONFIG_HOME"/notmuch/notmuchrc
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc
export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
export __GL_SHADER_DISK_CACHE_PATH="$XDG_CACHE_HOME"/nv
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export RANDFILE="$XDG_CACHE_HOME"/rnd
export RXVT_SOCKET="$XDG_RUNTIME_DIR"/urxvt/urxvt-"$(hostname)"
export JUPYTER_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/jupyter
export IPYTHONDIR=${XDG_CONFIG_HOME:-$HOME/.config}/ipython
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export WEECHAT_HOME="$XDG_CONFIG_HOME"/weechat
# export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
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
export KREW_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/krew"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
# TODO: temp disable
#export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
#export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config
export AZURE_CONFIG_DIR=$XDG_DATA_HOME/azure
# XDG: using aliases as workarounds
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
alias weechat='weechat -d "$XDG_CONFIG_HOME"/weechat'
export CARGO_HOME="$XDG_DATA_HOME"/cargo
# ansible almost-xdg
export ANSIBLE_HOME="${XDG_CONFIG_HOME}/ansible"
export ANSIBLE_CONFIG="${XDG_CONFIG_HOME}/ansible/ansible.cfg"
export ANSIBLE_GALAXY_CACHE_DIR="${XDG_CACHE_HOME}/ansible/galaxy_cache"
### ENDS: XDG ##################################################################


################################################################################
### PATH section
# set PATH so it includes user's private bin if it exists
# moved to .local/bin
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi
# XDG bin as well
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
# rust/cargo bin
if [ -d "$HOME/.local/share/cargo/bin" ] ; then
    PATH="$HOME/.local/share/cargo/bin:$PATH"
fi
# flatpack
if [ -d "/var/lib/flatpak/exports/bin" ] ; then
    PATH="$PATH:/var/lib/flatpak/exports/bin"
fi
# snap
if [ -d "/var/lib/snapd/snap/bin" ] ; then
    PATH="$PATH:/var/lib/snapd/snap/bin"
fi
# npm
if [ -d "$XDG_DATA_HOME/npm/bin" ] ; then
    PATH="$PATH:$XDG_DATA_HOME/npm/bin"
fi
# perl
if [ -d "/usr/bin/vendor_perl/" ] ; then
    PATH="$PATH:/usr/bin/vendor_perl"
fi
# path to user-installed ruby gems bin
if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
    PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi
# initialize b-scrips when starting a shell session
export BRING_DIR="$HOME/Code/Bring/b-scripts/bin"
if [[ -d "$BRING_DIR" && -x $BRING_DIR/b-scripts/bin/b ]]; then
    eval "$($BRING_DIR/b-scripts/bin/b init -)"
fi
export POSTEN_SLACK_USERNAME="chris.qvigstad@bring.com"
if [ -d "$HOME/Code/Bring/b-scripts/bin" ] ; then
    PATH="$PATH:$HOME/Code/Bring/b-scripts/bin"
fi
# posten path
# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
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
  --preview-window 'right:60%::wrap'
  --header-first --header-lines=0 --ansi"
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
zstyle ':fzf-tab:*' fzf-bindings 'insert:toggle+down,delete:deselect+down' 'ctrl-space:toggle' 'alt-j:down,alt-k:up' 'ctrl-u:preview-page-up' 'ctrl-d:preview-page-down' '?:toggle-preview'
# # preview directory's content with exa when completing cd
#zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath' # remember to use single quote here!!!
# TODO:  testing
# zstyle ':fzf-tab:complete:*:*' fzf-preview '${XDG_BIN_HOME}/lessfilter ${(Q)realpath}'
# testing ends
# zstyle ':fzf-tab:complete:*:*' fzf-preview 'less -e +G ${(Q)realpath}'
# enable descriptions as group labels
zstyle ':completion:*:descriptions' format '[%d]'
# actually group matches by description
zstyle ':completion:*' group-name ''
# Do not show preview for options
zstyle ':fzf-tab:complete:*:options' fzf-preview ''
# Do not show preview for arguments (TODO: not working?)
zstyle ':fzf-tab:complete:*:argument-1' fzf-preview ''
# Show group name (e.g. files / dirs / commands) in a separate column
zstyle ':fzf-tab:*' show-group full
# Show a short log when completing git branches
zstyle ':fzf-tab:complete:git-*:*' fzf-preview '
  case "$group" in
    branches) git log --oneline --decorate -n 20 -- "$word" ;;
    *)        ;;
  esac
'
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
# Fix backspace in insert mode
# https://superuser.com/questions/476532/how-can-i-make-zshs-vi-mode-behave-more-like-bashs-vi-mode/533685
bindkey "^?" backward-delete-char
vi-search-fix() {
    zle vi-cmd-mode
    zle .vi-history-search-backward
}
autoload vi-search-fix
zle -N vi-search-fix
bindkey -M viins '\e/' vi-search-fix
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
### Security section - gpg, yubikey, pass, gopass, password-store, tokens, etc
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
 cq_decrypt_diff() {
  : "#:desc: decrypt two GPG-encrypted files and run a diff tool"
  : "#:usage: cq_decrypt_diff <diff_program> <file1> <file2> [program_args...]"
  : "#:no-args: false"
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
# Load secrets env if the file exists
if [ -f "$XDG_CONFIG_HOME/zsh/secrets_env" ]; then
  source "$XDG_CONFIG_HOME/zsh/secrets_env"
fi
### ENDS: Security #############################################################


################################################################################
### Aliases and functions section
# update shell to include recently created group(s)
alias k=kubectl
compdef k=kubectl
alias cq_groups_refresh="exec sudo su -l $USER"
# Watch clipboard status
alias cq_clip_watch="watch -n 1 'echo \"PRIMARY (middle_mouse):\" && sselp && echo && \
    echo \"Clipboard (ctrl-c/p):\" && cb && echo && echo && \
    echo \"tmux-buffer:\" && tmux show-buffer && echo'"
alias watchclip="xsel -o | xclip -selection clipboard -i"
# Start a tmux session with session picker if already running, else waitfor resurrection
cq_tmux() {
  : "#:desc: attach to or create a tmux session with a chooser"
  : "#:usage: cq_tmux"
  : "#:no-args: true"
  local -a PICKER=(choose-tree -Zs)   # or (choose-tree -s) on older tmux
  local BOOTSTRAP="__bootstrap__"
  if [[ -n $TMUX ]]; then
    tmux "${PICKER[@]}"
    return
  fi
  if tmux list-sessions &>/dev/null; then
    tmux attach \; "${PICKER[@]}"
    return
  fi
  tmux new-session -d -s "$BOOTSTRAP" -n bootstrap 2>/dev/null || true
  local stop=$((SECONDS+6))
  while (( SECONDS < stop )); do
    if tmux list-sessions -F '#S' 2>/dev/null | grep -qxv "$BOOTSTRAP"; then
      break
    fi
    sleep 0.2
  done
  if tmux list-sessions -F '#S' 2>/dev/null | grep -qxv "$BOOTSTRAP"; then
    tmux kill-session -t "$BOOTSTRAP" &>/dev/null || true
    tmux attach \; "${PICKER[@]}"
  else
    tmux attach -t "$BOOTSTRAP"
  fi
}
cq_tmux_split_dirs() {
  : "#:desc: split tmux panes for matching subdirectories"
  : "#:usage: cq_tmux_split_dirs [substring]"
  : "#:no-args: true"
  # Check if inside a Tmux session
  if [ -z "$TMUX" ]; then
    echo "You are not in a Tmux session. Please start a Tmux session first."
    return 1
  fi
  # Get the substring to filter directories (optional)
  local substring="${1:-}"
  # Get a list of directories matching the substring in the current directory
  local dirs=()
  while IFS= read -r dir; do
    dirs+=("$dir")
  done < <(find . -maxdepth 1 -type d -iname "*$substring*" ! -path "." | sort)
  # Debug: Print the directories found
  # echo "dirs: ${dirs[@]}"
  # If no matching directories are found, exit
  if [ ${#dirs[@]} -eq 0 ]; then
    echo "No directories found matching '${substring}'."
    return 1
  fi
  # Use the current pane for the first directory (1-based indexing in Zsh)
  local first_dir="${dirs[1]}"
  first_dir="${first_dir#./}" # Remove the "./" prefix from the directory name
  # Debug: Print the first directory as raw and cleaned
  # echo "Raw first directory: ${dirs[1]}"
  # echo "Cleaned first directory: $first_dir"
  if [ -n "$first_dir" ]; then
    tmux send-keys "cd \"$first_dir\" && exec $SHELL" C-m
  else
    echo "Error: First directory is empty or invalid."
    return 1
  fi
  # Remove the first directory from the list (adjust for 1-based indexing)
  dirs=("${dirs[@]:1}")
  # For each remaining directory, create a vertical split and cd into it
  for dir in "${dirs[@]}"; do
    dir="${dir#./}" # Remove the "./" prefix from the directory name
    # Debug: Print the current directory being processed
    # echo "Splitting for directory: $dir"
    tmux split-window -v "cd \"$dir\" && exec $SHELL"
    tmux select-layout even-horizontal
  done
}
cq_tmux_split_dirs_add() {
  : "#:desc: add tmux pane splits for matching subdirectories"
  : "#:usage: cq_tmux_split_dirs_add [substring]"
  : "#:no-args: false"
  # Check if inside a Tmux session
  if [ -z "$TMUX" ]; then
    echo "You are not in a Tmux session. Please start a Tmux session first."
    return 1
  fi
  # Get the substring to filter directories (optional)
  local substring="${1:-}"
  # Get a list of directories matching the substring in the current directory
  local dirs=($(find . -maxdepth 1 -type d -iname "*$substring*" ! -path . | sort))
  # If no matching directories are found, exit
  if [ ${#dirs[@]} -eq 0 ]; then
    echo "No directories found matching '${substring}'."
    return 1
  fi
  # For each directory, create a vertical split and cd into it
  for dir in "${dirs[@]}"; do
    tmux split-window -v "cd $dir && exec $SHELL"
    tmux select-layout even-horizontal
  done
}
cq_mdsearch() {
    : "#:desc: search markdown files with ugrep and preview with glow"
    : "#:usage: mdsearch [search_term]"
    : "#:no-args: false"
    local arg="${1:-""}"
    CWD="$(pwd)"
    cd $HOME/Sync/Wiki/Tech/Tech
    # ugrep -Qrl --split --context=3 -t markdown --view="glow -p" -e "$arg"
    ugrep -Qrl -%% -Z4 --split --context=3 -t markdown --no-confirm --view="glow -p" -e "$arg"
    cd "$CWD"
}
# ssh tunnel
cq_ssh-tunnel() {
  : "#:desc: interactive SSH tunnel builder (local/remote/SOCKS)"
  : "#:usage: cq_ssh-tunnel"
  : "#:no-args: true"
  emulate -L zsh -o pipefail
  local -a hosts ssh_config_files
  local line host dest tunnel_type bind_addr local_port dest_host dest_port
  # ---- Collect ssh config files ----
  [[ -f ~/.ssh/config ]] && ssh_config_files+=(~/.ssh/config)
  ssh_config_files+=(~/.ssh/config.d/*.conf(N))  # ignore if dir doesn't exist / no matches
  # ---- Hosts from ssh config (Host entries, no wildcards) ----
  for cfg in $ssh_config_files; do
    while IFS= read -r line; do
      # Only lines starting exactly with "Host "
      [[ $line == Host\ * ]] || continue
      # Remove leading "Host " and split on whitespace
      line=${line#Host }
      for host in ${(z)line}; do
        [[ $host == *"*"* || $host == *"?"* ]] && continue
        hosts+="$host"
      done
    done < "$cfg"
  done
  # ---- Hosts from known_hosts ----
  if [[ -f ~/.ssh/known_hosts ]]; then
    while IFS=' ' read -r host rest; do
      # skip empty / commented / hashed entries
      [[ -z $host || $host == \#* || $host == \|* ]] && continue
      # known_hosts may store multiple hosts separated by commas
      for h in ${(s:,:)host}; do
        # strip [ ] around IPv6 entries without using globs
        if [[ ${h[1,1]} == "[" && ${h[-1,1]} == "]" ]]; then
          h=${h[2,-2]}
        fi
        hosts+="$h"
      done
    done < ~/.ssh/known_hosts
  fi
  # ---- Unique & sorted ----
  hosts=(${(u)hosts})
  hosts=(${(on)hosts})
  # ---- Pick destination (user@host / Host alias) ----
  if (( ${#hosts} > 0 )) && command -v fzf >/dev/null 2>&1; then
    dest=$(printf '%s\n' "${hosts[@]}" \
      | fzf --prompt='SSH destination (alias or host, can include user@): ')
  else
    [[ ${#hosts} -gt 0 ]] && print "No fzf; you have ${#hosts} known hosts."
    vared -p "SSH destination (alias, host, or user@host): " dest
  fi
  [[ -z $dest ]] && { print -u2 "Aborted: no destination selected."; return 1; }
  # ---- Tunnel type ----
  print ""
  print "What kind of tunnel do you want?"
  print "  1) Local  (-L): expose a remote service on this machine"
  print "  2) Remote (-R): expose a local service on the remote machine"
  print "  3) SOCKS  (-D): dynamic proxy (SOCKS5 on a local port)"
  vared -p "Choose 1/2/3 [1]: " tunnel_type
  [[ -z $tunnel_type ]] && tunnel_type=1
  case $tunnel_type in
    1)  # Local forward
      print ""
      vared -p "Local bind address on THIS machine [127.0.0.1]: " bind_addr
      [[ -z $bind_addr ]] && bind_addr=127.0.0.1
      vared -p "Local port to listen on (on THIS machine, e.g. 8080): " local_port
      vared -p "Target host as seen FROM the SSH server (e.g. localhost, db.internal): " dest_host
      vared -p "Target port on that host (e.g. 5432): " dest_port
      if [[ -z $local_port || -z $dest_host || -z $dest_port ]]; then
        print -u2 "Missing one or more required values. Aborting."
        return 1
      fi
      print ""
      print "Creating LOCAL tunnel:"
      print "  Local:  ${bind_addr}:${local_port}"
      print "  Remote: ${dest_host}:${dest_port} (as seen from $dest)"
      print ""
      print "Command: ssh -N -L ${bind_addr}:${local_port}:${dest_host}:${dest_port} $dest"
      ssh -N -L "${bind_addr}:${local_port}:${dest_host}:${dest_port}" "$dest"
      ;;
    2)  # Remote forward
      print ""
      vared -p "Remote bind address on SSH SERVER [127.0.0.1]: " bind_addr
      [[ -z $bind_addr ]] && bind_addr=127.0.0.1
      vared -p "Remote port to listen on (ON THE SSH SERVER, e.g. 8080): " local_port
      vared -p "Target host reachable FROM THIS machine (e.g. localhost, service.internal): " dest_host
      vared -p "Target port on that host (e.g. 80): " dest_port
      if [[ -z $local_port || -z $dest_host || -z $dest_port ]]; then
        print -u2 "Missing one or more required values. Aborting."
        return 1
      fi
      print ""
      print "Creating REMOTE tunnel:"
      print "  Remote: ${bind_addr}:${local_port} (on $dest)"
      print "  Local : ${dest_host}:${dest_port} (from here)"
      print ""
      print "Command: ssh -N -R ${bind_addr}:${local_port}:${dest_host}:${dest_port} $dest"
      ssh -N -R "${bind_addr}:${local_port}:${dest_host}:${dest_port}" "$dest"
      ;;
    3)  # SOCKS proxy
      print ""
      bind_addr=127.0.0.1
      vared -p "Local port for SOCKS proxy (on THIS machine, e.g. 1080): " local_port
      if [[ -z $local_port ]]; then
        print -u2 "Missing port. Aborting."
        return 1
      fi
      print ""
      print "Creating SOCKS (dynamic) tunnel:"
      print "  SOCKS proxy on ${bind_addr}:${local_port}"
      print ""
      print "Command: ssh -N -D ${bind_addr}:${local_port} $dest"
      ssh -N -D "${bind_addr}:${local_port}" "$dest"
      ;;
    *)
      print -u2 "Invalid choice '$tunnel_type'. Aborting."
      return 1
      ;;
  esac
}
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
    : "#:desc: append text to a file using sudo"
    : "#:usage: cq_sudo_append <file> <text...>"
    : "#:no-args: false"
    local file="$1"
    shift
    local text="$*"
    echo "$text" | sudo tee -a "$file" > /dev/null
}
# send command to all tmux sessions
cq_tmux_cmd_all() {
  : "#:desc: send a command to all panes in the current tmux window"
  : "#:usage: cq_tmux_cmd_all <command...>"
  : "#:no-args: false"
  # Get the current session and window
  local current_session current_window
  current_session=$(tmux display-message -p '#S')  # Active session
  current_window=$(tmux display-message -p '#I')  # Active window
  # Iterate over all panes in the current window and send the command
  for pane in $(tmux list-panes -t "$current_session:$current_window" -F '#P' | sort); do
    tmux send-keys -t "$current_session:$current_window.$pane" "$*" C-m
  done
}
cq_tmux_cmd_globally() {
    : "#:desc: send a command to all panes in all tmux sessions"
    : "#:usage: cq_tmux_cmd_globally <command...>"
    : "#:no-args: false"
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
alias crypt-sync="${HOME}/.local/bin/crypt-sync/crypt-sync.sh"
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
alias skraper='(cd ~/.local/bin/Skraper && mono SkraperUI.exe)'
alias i3_swap_1and2='i3-msg "rename workspace 1 to temporary; rename workspace 2 to 1; rename workspace temporary to 2"'
alias spotify-tui='spotify_player'
alias cq_snd_restart="systemctl --user restart pipewire pipewire-pulse wireplumber"
alias tfinit='terraform init -backend-config=tf-init.conf'
alias helm-completion='source <(helm completion zsh)'
# swap workspaces 1 and 2
# make this a script for use in i3
 cq_autorandr() {
    : "#:desc: pick an autorandr profile via rofi and apply it"
    : "#:usage: cq_autorandr"
    : "#:no-args: true"
    autorandr $(autorandr | cut -d' ' -f1|rofi -dmenu)
}
 i3_swap() {
    i3-msg "rename workspace $1 to temporary;
            rename workspace $2 to $1;
            rename workspace temporary to $2"
}
# start tmux sessions
 cq_tmux_startup() {
    : "#:desc: start predefined tmux sessions if missing"
    : "#:usage: cq_tmux_startup"
    : "#:no-args: true"
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
cq_completions-list () {
    : "#:desc: list loaded zsh completion definitions"
    : "#:usage: cq_completions-list"
    : "#:no-args: true"
    for command completion in ${(kv)_comps:#-*(-|-,*)}
    do
        printf "%-32s %s\n" $command $completion
    done | sort
}
# what package does a binary belong to
pacwhich() { pacman -Qo $(which $1) }
# Build/install chosen AUR helper (paru or yay) in a tmpfs-backed dir when available
cq_aur_install_helper() {
  : "#:desc: build/install chosen AUR helper (paru or yay)"
  : "#:usage: cq_aur_install_helper {paru|yay}"
  : "#:no-args: false"
  emulate -L zsh
  setopt errexit nounset pipefail
  local helper="${1:-}"
  case "$helper" in
    paru|yay) ;;
    *) print -ru2 -- "usage: aur_install_helper {paru|yay}"; return 2 ;;
  esac
  local tmpbase repo dir url
  tmpbase="${XDG_RUNTIME_DIR:-/run/user/$UID}"
  [[ -d "$tmpbase" && -w "$tmpbase" ]] || tmpbase="/tmp"
  command -v git >/dev/null     || { print -ru2 -- "git missing"; return 1; }
  command -v makepkg >/dev/null || { print -ru2 -- "makepkg missing (base-devel)"; return 1; }
  url="https://aur.archlinux.org/${helper}.git"
  repo="$(mktemp -d "$tmpbase/aur-${helper}.XXXXXX")"
  dir="$repo/$helper"
  print -r -- "==> $helper: building in $repo"
  git clone --depth=1 "$url" "$dir"
  ( cd "$dir" && makepkg -si --noconfirm )
  rm -rf -- "$repo"
}
# Install paru
 cq_paru_install() {
    : "#:desc: clone, build, and install paru from the AUR"
    : "#:usage: cq_paru_install"
    : "#:no-args: true"
    if ! command -v git >/dev/null 2>&1; then
        sudo pacman -S git
    fi
    mkdir -p ~/tmp/
    git clone https://aur.archlinux.org/paru.git
    cd ~/tmp/paru
    makepkg -si
}
# Set env from KEY=value list in file
cq_env_arg() {
  : "#:desc: source an env file with exported variables"
  : "#:usage: cq_env_arg <file> [args...]"
  : "#:no-args: false"
  set -o allexport; source $@; set +o allexport
}
cq_env_select() {
  : "#:desc: pick and source an env file from ~/.config/env"
  : "#:usage: cq_env_select"
  : "#:no-args: true"
  set -o allexport; source $(fd .conf ~/.config/env -t f|fzf); set +o allexport
}
# Run command with env from ./.env
cq_with_env() {
    : "#:desc: run a command with environment from ./.env"
    : "#:usage: cq_with_env <command> [args...]"
    : "#:no-args: false"
    (set -a && . ./.env && "$@")
}
 cq_rspamd() {
    : "#:desc: open an SSH tunnel to rspamd and open the web UI"
    : "#:usage: cq_rspamd <ssh_destination>"
    : "#:no-args: false"
    local domain_name=$1
    if [ -z "$domain_name" ]; then
        echo "Usage: cq_rspamd <domain_name>"
        return 1
    fi
    ssh -f -N -L 11334:localhost:11334 "$domain_name"
    xdg-open http://localhost:11334
}
cq_rspamd_stop() {
    : "#:desc: stop the rspamd SSH tunnel created by cq_rspamd"
    : "#:usage: cq_rspamd_stop"
    : "#:no-args: true"
    pkill -f "ssh -f -N -L 11334:localhost:11334"
}
# k8s aliases and functions
kq_eks_drain_nodes() {
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
kq_label_namespaces() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: label_namespaces <namespace1> <namespace2> ..."
    return 1
  fi
  for namespace in "$@"; do
    echo "Labeling namespace: $namespace"
    kubectl label ns "$namespace" goldilocks.fairwinds.com/enabled=true --overwrite
    if [[ $? -ne 0 ]]; then
      echo "Failed to label namespace: $namespace" >&2
    fi
  done
}
kq_k8s_run_image_ns() {
  local image=$1
  local ns=$2
  if [[ -z $image || -z $ns ]]; then
    echo "Usage: cq_k8s_run_image_ns <image> <namespace>"
    return 1
  fi
  local name="nettest-$(head /dev/urandom | tr -dc a-z0-9 | head -c6)"
  kubectl run "$name" \
    -n "$ns" \
    --rm -i -t \
    --image="$image" \
    --restart=Never \
    --overrides="
{
  \"spec\": {
    \"automountServiceAccountToken\": false,
    \"securityContext\": {
      \"seccompProfile\": {
        \"type\": \"RuntimeDefault\"
      }
    },
    \"containers\": [{
      \"name\": \"$name\",
      \"image\": \"$image\",
      \"command\": [\"sh\"],
      \"stdin\": true,
      \"tty\": true,
      \"securityContext\": {
        \"runAsUser\": 1000,
        \"runAsGroup\": 1000,
        \"fsGroup\": 1000,
        \"supplementalGroups\": [1000],
        \"runAsNonRoot\": true,
        \"allowPrivilegeEscalation\": false
      }
    }]
  }
}"
}
kq_bring_aksconf_split() {
  kubectl config view --minify --flatten --context=cf-dev-noe-applications-aks-01 > $XDG_CONFIG_HOME/kube/bring-dev.yaml
  kubectl config view --minify --flatten --context=cf-test-noe-applications-aks-01 > $XDG_CONFIG_HOME/kube/bring-test.yaml
  kubectl config view --minify --flatten --context=cf-qa-noe-applications-aks-01 > $XDG_CONFIG_HOME/kube/bring-qa.yaml
  kubectl config view --minify --flatten --context=cf-prod-noe-applications-aks-01 > $XDG_CONFIG_HOME/kube/bring-prod.yaml
}
# Always use bring.azurecr.io/cache/wbitt/network-multitool
kq_nettool_shell() {
  if [ -z "$1" ]; then
    echo "Usage: knettool <namespace>"
    return 1
  fi
  local ns="$1"
  kubectl run -n "$ns" nettool \
    --rm -it --restart=Never \
    --image=bring.azurecr.io/cache/wbitt/network-multitool \
    -- bash
}
kq_shell_on_pod() {
  if [ -z "$1" ]; then
    echo "Usage: kq_shell_on_pod <namespace> [container]"
    return 1
  fi
  local ns="$1"
  local container="$2"
  local pod
  pod=$(kubectl get pods -n "$ns" --no-headers -o custom-columns=":metadata.name" | fzf --prompt="Pick a pod in $ns: ")
  if [ -z "$pod" ]; then
    echo "No pod selected"
    return 1
  fi
  echo "Connecting to pod: $pod (ns: $ns)"
  if [ -n "$container" ]; then
    kubectl exec -n "$ns" -it "$pod" -c "$container" -- /bin/sh
  else
    kubectl exec -n "$ns" -it "$pod" -- /bin/sh
  fi
}
# kq_shell_on_deployment [ns] [deployment]
kq_shell_on_deployment() {
  command -v jq >/dev/null || { echo "requires: jq" >&2; return 1; }
  local ns="${1:-}" dep="${2:-}" sel pod containers container num
  # pick namespace
  if [ -z "$ns" ]; then
    if command -v fzf >/dev/null; then
      ns="$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf --prompt='ns> ' --height=40%)" || return 1
    else
      ns="$(kubectl get ns -o jsonpath='{.items[0].metadata.name}')" || return 1
    fi
  fi
  # pick deployment
  if [ -z "$dep" ]; then
    if command -v fzf >/dev/null; then
      dep="$(kubectl -n "$ns" get deploy -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf --prompt="deploy[$ns]> " --height=40%)" || return 1
    else
      dep="$(kubectl -n "$ns" get deploy -o jsonpath='{.items[0].metadata.name}')" || return 1
    fi
  fi
  # selector from deployment
  sel="$(kubectl -n "$ns" get deploy "$dep" -o json \
        | jq -r '.spec.selector.matchLabels | to_entries | map("\(.key)=\(.value)") | join(",")')"
  [ -n "$sel" ] || { echo "no selector on $ns/$dep" >&2; return 1; }
  # pick a Running+Ready pod of that deployment
  if command -v fzf >/dev/null; then
    pod="$(kubectl -n "$ns" get pod -l "$sel" -o json \
      | jq -r '.items[]
               | select(.status.phase=="Running")
               | select([.status.containerStatuses[]? | .ready] | all)
               | .metadata.name' \
      | fzf --prompt="pod[$dep]> " --height=40%)" || return 1
  else
    pod="$(kubectl -n "$ns" get pod -l "$sel" -o jsonpath='{.items[0].metadata.name}')" || return 1
  fi
  [ -n "$pod" ] || { echo "no pod for $ns/$dep" >&2; return 1; }
  # list LIVE containers (includes injected sidecars)
  containers="$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}')"
  [ -n "$containers" ] || { echo "no containers in pod $pod" >&2; return 1; }
  # choose container (always prompt if multiple; set KQ_ALWAYS=1 to force prompt even with one)
  num="$(printf '%s\n' "$containers" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ "${KQ_ALWAYS:-0}" != 0 ] || { [ "$num" -gt 1 ] && command -v fzf >/dev/null; }; then
    container="$(printf '%s\n' "$containers" | fzf --prompt="container[$pod]> " --height=40%)" || return 1
  else
    container="$(printf '%s\n' "$containers" | head -n1)"
  fi
  # exec
  kubectl -n "$ns" exec -it "$pod" -c "$container" -- bash \
  || kubectl -n "$ns" exec -it "$pod" -c "$container" -- sh \
  || kubectl -n "$ns" exec -it "$pod" -c "$container" -- ash
}
kq_cilium_shell_on_pod_node() {
  if [ -z "$1" ]; then
    echo "Open a cilium shell on the node where a pod is running"
    echo "Usage: kq_cilium_shell_on_pod_node <namespace> [container]"
    return 1
  fi
  local ns="$1"
  local container="$2"
  local pod
  pod=$(kubectl get pods -n "$ns" --no-headers -o custom-columns=":metadata.name" | fzf --prompt="Pick a pod in $ns: ")
  # connect
  NODE=$(kubectl -n fqdn-ns get pod -l app=multitool -o jsonpath='{.items[0].spec.nodeName}')
  CIL=$(kubectl -n kube-system get pod -l k8s-app=cilium -o jsonpath="{.items[?(@.spec.nodeName=='$NODE')].metadata.name}")
  kubectl -n kube-system exec -it "$CIL" -- bash
  # kubectl -n kube-system exec "$CIL" -- cilium-dbg fqdn cache list
}
kq_create_pod_shell() {
  if [ $# -ne 2 ]; then
    echo "Create a pod with specified image in specified namespace and open a shell"
    echo "Usage: kq_create_pod_shell <namespace> <image>"
    return 1
  fi
  local ns="$1"
  local img="$2"
  kubectl run -n "$ns" testpod \
    --rm -it --restart=Never \
    --image="$img" \
    -- bash
}
### Self hosting functions
cq_sync_dotfiles_to_server() {
    : "#:desc: rsync dotfiles to a server using a file list"
    : "#:usage: cq_sync_dotfiles_to_server <server-name>"
    : "#:no-args: false"
    local server=$1
    local source_dir="$HOME"
    local dest_user="chrisq"
    local dest_path="/home/chrisq"
    local rsync_dir="$HOME/.config/rsync"
    local files_list_name="server-dotfiles.txt"
    # Check if the server name is provided
    if [[ -z "$server" ]]; then
        echo "Usage: cq_sync_dotfiles_to_server <server-name>"
        return 1
    fi
    # Check if rsync-files.txt exists
    local files_path="$rsync_dir/$files_list_name"
    if [[ ! -f "$files_path" ]]; then
        echo "Error: $files_path not found. Please create this file with the list of files to sync."
        return 1
    fi
    # Check if the exclusion file exists, same name as files list but with .exclude extension
    local exclude_path="$files_path.exclude"
    if [[ -f "$exclude_path" ]]; then
        rsync -avz -r --delete --files-from=<(grep -v '^\s*#' "$files_path") --exclude-from="$exclude_path" "$source_dir/" "$dest_user@$server:$dest_path"
    else
        rsync -avz -r --delete --files-from=<(grep -v '^\s*#' "$files_path") "$source_dir/" "$dest_user@$server:$dest_path"
    fi
    echo "Dotfiles synchronized successfully to $server"
}
cq_sync_gpgssh() {
    : "#:desc: rsync gpg/ssh config to a server using a file list"
    : "#:usage: cq_sync_gpgssh <server-name>"
    : "#:no-args: false"
    local server=$1
    local source_dir="$HOME"
    local dest_user="chrisq"
    local dest_path="/home/chrisq"
    local rsync_dir="$HOME/.config/rsync"
    local files_list_name="gpgssh.txt"
    # Check if the server name is provided
    if [[ -z "$server" ]]; then
        echo "Usage: cq_sync_gpgssh <server-name>"
        return 1
    fi
    # Check if rsync-files.txt exists
    local files_path="$rsync_dir/$files_list_name"
    if [[ ! -f "$files_path" ]]; then
        echo "Error: $files_path not found. Please create this file with the list of files to sync."
        return 1
    fi
    # Check if the exclusion file exists, same name as files list but with .exclude extension
    local exclude_path="$files_path.exclude"
    if [[ -f "$exclude_path" ]]; then
        rsync -avz -r --delete --files-from=<(grep -v '^\s*#' "$files_path") --exclude-from="$exclude_path" "$source_dir/" "$dest_user@$server:$dest_path"
    else
        rsync -avz -r --delete --files-from=<(grep -v '^\s*#' "$files_path") "$source_dir/" "$dest_user@$server:$dest_path"
    fi
    echo "Dotfiles synchronized successfully to $server"
}
alias cq_soud_restart='systemctl --user restart pipewire-pulse pipewire wireplumber'
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
znap source ohmyzsh/ohmyzsh plugins/{aws,direnv,docker-compose,fabric,git,nmap,pip,python,sudo,systemd,taskwarrior,terraform}
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
# ENDS: breaks when higher up for whatever reason
### ENDS: zsh-snap #############################################################


################################################################################
### Override section - override keybindings and such from modules and tools above
## Aliases
# eza -a1@hlo --icons --group-directories-first
alias ls="eza -a1@hlo --group-directories-first --classify --git --icons"
alias ll="ls -l"
alias lsl="ls -l"
alias lla="ls -la"
alias lsla="ls -la"
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
#  Q() {
#     qcmd=$(compgen -c | grep '^cq' | fzf)
#     $qcmd
# }
abbrev-alias -g G="| rg"
# Powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
### ENDS: Override #############################################################


################################################################################
###  Personal functions and scripts system
## Howto add metadata to functions and scripts:
# Script/function header example, must be start of file or function:
# #:desc: Dump a DB to S3
# #:usage: cq_db_dump <db_name> [--full]
# #:noargs: true
# Helper function to extract a specific tag value
#
# Uses /usr/bin/awk to ensure execution regardless of PATH issues.
# TODO: source from ZDOTDIR if exists
source ~/.config/zsh/Q.zsh
zle -N Q_widget
bindkey '^Q' Q_widget
### ENDS: Personal functions and scripts system ################################
