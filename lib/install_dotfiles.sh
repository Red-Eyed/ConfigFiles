#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

cd $ROOT_DIR/dotfiles

stow --adopt -d $PWD -t $HOME -S *
