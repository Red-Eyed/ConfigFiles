#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

oh_my_bash_dir="$HOME/.oh-my-bash"
oh_my_bash_backup="$HOME/.oh-my-bash.bak"

if dir_exists "$oh_my_bash_dir" && ! dir_exists "$oh_my_bash_dir/.git"; then
    if dir_exists "$oh_my_bash_backup"; then
        die "Cannot back up $oh_my_bash_dir because $oh_my_bash_backup already exists"
    fi

    warn "Backing up non-git oh-my-bash directory to $oh_my_bash_backup"
    mv "$oh_my_bash_dir" "$oh_my_bash_backup"
fi

clone_pinned_repo https://github.com/ohmybash/oh-my-bash.git "$oh_my_bash_dir" 20
