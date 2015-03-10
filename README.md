# dotfiles README/HOWTO

##Setting up for the first time

coming soon

##Checkout on new machine
## WARNING: Will overwrite your files of the same name
```sh
alias dotfiles="git --work-tree=$HOME/ --git-dir=$HOME/dotfiles.git"
git clone --bare https://github.com/chrisaq/dotfiles.git ~/dotfiles.git
dotfiles status -s -uno
dotfiles reset HEAD
dotfiles checkout ~
git config --global core.excludesfile $HOME/.gitignore_global # this file was created on the initial setup
```
