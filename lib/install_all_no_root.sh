#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

./install_dotfiles.sh
./install_uv.sh
./install_oh-my-zsh.sh
./install_golang.sh
./install_node.sh
