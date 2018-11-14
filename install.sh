#!/bin/bash

git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh

rsync -a linux/.bashrc $HOME
rsync -a linux/.zshrc  $HOME
rsync -a linux/.vimrc  $HOME

sudo rsync linux/etc/zsh/ /etc/zsh/

sudo apt install vim

