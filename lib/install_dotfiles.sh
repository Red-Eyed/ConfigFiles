#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

python3 $ROOT_DIR/lib stow --src=$ROOT_DIR/dotfiles --dst=$HOME
