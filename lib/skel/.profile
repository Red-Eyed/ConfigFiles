# shellcheck shell=sh

if [ -n "${BASH_VERSION:-}" ]; then
    case $- in
        *i*)
            if [ -r "$HOME/.bashrc" ]; then
                # shellcheck source=/dev/null
                . "$HOME/.bashrc"
            elif [ -r "$HOME/.posixrc" ]; then
                # shellcheck source=/dev/null
                . "$HOME/.posixrc"
            fi
            ;;
        *)
            if [ -r "$HOME/.posixrc" ]; then
                # shellcheck source=/dev/null
                . "$HOME/.posixrc"
            fi
            ;;
    esac
elif [ -r "$HOME/.posixrc" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.posixrc"
fi
