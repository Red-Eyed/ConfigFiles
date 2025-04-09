#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

if [[ ! -d $HOME/.oh-my-zsh ]]; then
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
else
    cd $HOME/.oh-my-zsh
    git pull
    cd -
fi

if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s $(which zsh)
fi
