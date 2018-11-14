#!/bin/bash

sudo apt install \
    vim \
    git \
    zsh \
    htop \
    pydf \
    meld

git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh

rsync -a linux/.bashrc $HOME
rsync -a linux/.zshrc  $HOME
rsync -a linux/.vimrc  $HOME

sudo rsync linux/etc/zsh/ /etc/zsh/

chsh -s $(which zsh)

