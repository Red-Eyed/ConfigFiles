#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

clone_pinned_repo https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh 20
