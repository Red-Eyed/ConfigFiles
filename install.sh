#!/bin/bash

cd $(dirname $(readlink -f $0))

sudo apt install --yes \
    python3-pip \
    vim \
    git \
    zsh \
    htop \
    meld

pip3 install --user \
    pydf \
    speedtest-cli \
    ipython


if [[ ! -d $HOME/.oh-my-zsh ]]; then
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
else
    cd $HOME/.oh-my-zsh
    git pull
    cd -
fi

rsync -a linux/.bashrc $HOME
rsync -a linux/.zshrc  $HOME
rsync -a linux/.vimrc  $HOME

sudo rsync linux/etc/zsh/ /etc/zsh/

chsh -s $(which zsh)

