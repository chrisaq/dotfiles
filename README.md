# dotfiles README/HOWTO

##Setting up for the first time

###create git-dotfiles-dir and add alias

```
mkdir $HOME/.dotfiles.git
# add the below to your .zshrc or .bashrc
alias dotfiles="git --work-tree=$HOME/ --git-dir=$HOME/.dotfiles.git"
```

###create additional .gitignore and add it to git config:

```
cat <<EOF
# ignore all by default
*
# specific ignores
*.pyc
node_modules
# do not ignore:
!bin/
!.vimrc
!.tmux.conf
EOF > $HOME/.gitignore
```

###init repo:

```
dotfiles init
dotfiles add -f $HOME/.bash_profile $HOME/.bashrc $HOME/.bash_aliases
dotfiles commit -m 'Initial commit'
dotfiles remote add origin git@github.com:chrisaq/dotfiles.git
dotfiles push origin master
```

##Checkout on new machine
### WARNING: Will overwrite your files of the same name
```sh
alias dotfiles="git --work-tree=$HOME/ --git-dir=$HOME/.dotfiles.git"
git clone --bare https://github.com/chrisaq/dotfiles.git ~/.dotfiles.git
dotfiles status -s -uno
dotfiles reset HEAD
dotfiles checkout ~
dotfiles push --set-upstream origin master
# TODO: Figure out a better way to gitignore
#git config --global core.excludesfile $HOME/.gitignore_global # this file was created on the initial setup
```
