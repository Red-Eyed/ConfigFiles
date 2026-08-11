if [[ -r "$HOME/.posixrc" ]]; then
    source "$HOME/.posixrc"
fi

if [[ -d "$HOME/.zshrc.d" ]]; then
    for zsh_config in "$HOME"/.zshrc.d/*.zsh(N); do
        [[ -r "$zsh_config" ]] && source "$zsh_config"
    done
    unset zsh_config
fi
