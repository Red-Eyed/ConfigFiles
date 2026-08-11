# shellcheck shell=bash

if [[ -r "$HOME/.profile" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.profile"
elif [[ -r "$HOME/.bashrc" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
fi
