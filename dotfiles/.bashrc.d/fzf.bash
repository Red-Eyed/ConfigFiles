# shellcheck shell=bash

command -v fzf >/dev/null 2>&1 || return 0

if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
elif command -v sed >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'sed -n \"1,200p\" {}'"
fi

for fzf_file in \
    "$HOME/.fzf.bash" \
    /usr/share/doc/fzf/examples/key-bindings.bash \
    /usr/share/fzf/key-bindings.bash \
    /usr/share/doc/fzf/examples/completion.bash \
    /usr/share/fzf/completion.bash
do
    if [[ -r "$fzf_file" ]]; then
        # shellcheck source=/dev/null
        source "$fzf_file"
    fi
done
