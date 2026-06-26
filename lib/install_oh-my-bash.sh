#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

clone_pinned_repo https://github.com/ohmybash/oh-my-bash.git ~/.oh-my-bash 20
