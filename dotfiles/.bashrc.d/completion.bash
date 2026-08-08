# shellcheck shell=bash

for completion_file in \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
do
    if [[ -r "$completion_file" ]]; then
        # shellcheck source=/dev/null
        source "$completion_file"
        break
    fi
done

if [[ -r "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi
