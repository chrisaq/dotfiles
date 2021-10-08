# dotfiles README/HOWTO

## Setting up for the first time

### create git-dotfiles-dir and add alias

```
mkdir $HOME/.dotfiles.git
# add the below to your .zshrc or .bashrc
alias dotfiles="git --work-tree=$HOME/ --git-dir=$HOME/.dotfiles.git"
```

### create additional .gitignore and add it to git config:

```
cat <<EOF
# ignore all by default
*
EOF > $HOME/.gitignore
```

### init repo:

```
dotfiles init
dotfiles add -f $HOME/.bash_profile $HOME/.bashrc $HOME/.bash_aliases
dotfiles commit -m 'Initial commit'
dotfiles remote add origin git@github.com:chrisaq/dotfiles.git
dotfiles push origin master
```

## Checkout on new machine
### WARNING: Will overwrite your files of the same name
```sh
alias dotfiles="git --work-tree=$HOME/ --git-dir=$HOME/.dotfiles.git"
git clone --bare https://github.com/chrisaq/dotfiles.git ~/.dotfiles.git
dotfiles status -s -uno
dotfiles reset HEAD
dotfiles checkout ~
dotfiles remote set-url origin ssh://git@github.com/chrisaq/dotfiles.git
dotfiles push --set-upstream origin master
# TODO: Figure out a better way to gitignore
#git config --global core.excludesfile $HOME/.gitignore_global # this file was created on the initial setup
```

## Per machine config in separate dotfiles repo

To keep the same type of system for dotfiles that need to be unique per machine,
do the same as the above, but with different alias.

This lets you keep shared dotfiles sync'ed with the `dotfiles` command, while machine
specific config is managed with `dotlocal`.

### Local machine dotfiles setup

```
mkdir $HOME/.dotfiles-$(hostname).git
# add the below to your .zshrc or .bashrc
alias dotlocal="git --work-tree=$HOME/ --git-dir=$HOME/.dotfiles-$(hostname).git"
dotlocal remote add origin git@github.com:chrisaq/dotfiles-$(hostname).git
dotlocal add -f .gitignore
dotlocal commit -am 'gitignore, shared'
dotolcal push
```

### Moving files from shared dotfiles to single machine

When config that needs to be different per machine is located and is to be moved,
use git's `dotfiles rm --cached <file>` or recursive with `dotfiles rm -r --cached <dir>` with `dotfiles`.
The files/dirs can then be added as normal with `dotlocal add -f <file/dir>`.


