#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

./install_oh-my-zsh.sh
./install_dotfiles.sh
./install_apt_headless.sh
./install_uv.sh

