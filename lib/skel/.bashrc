# shellcheck shell=bash

case $- in
    *i*) ;;
    *) return ;;
esac

if [[ -r "$HOME/.posixrc" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.posixrc"
fi

if [[ -d "$HOME/.bashrc.d" ]]; then
    for bash_config in "$HOME"/.bashrc.d/*.bash; do
        # shellcheck source=/dev/null
        [[ -r "$bash_config" ]] && source "$bash_config"
    done
    unset bash_config
fi
