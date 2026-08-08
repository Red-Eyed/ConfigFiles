(( $+commands[fzf] )) || return 0

if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

if (( $+commands[bat] )); then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
elif (( $+commands[sed] )); then
    export FZF_CTRL_T_OPTS="--preview 'sed -n \"1,200p\" {}'"
fi

for fzf_file in \
    "$HOME/.fzf.zsh" \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/doc/fzf/examples/completion.zsh \
    /usr/share/fzf/completion.zsh
do
    [[ -r "$fzf_file" ]] && source "$fzf_file"
done
