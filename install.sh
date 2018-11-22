#!/bin/bash

cd $(dirname $(readlink -f $0))

sudo apt install --yes \
    vim \
    git \
    zsh \
    htop \
    meld

if [[ "$(which pip3)" == "" ]]; then
    sudo apt install python3-pip --yes
fi


pip3 install --upgrade  --user \
    pip \
    pydf \
    speedtest-cli \
    ipython \
    pipenv

sudo apt purge python3-pip --yes

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

if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s $(which zsh)
fi

