#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

if ! dir_exists ~/.oh-my-zsh; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
fi
