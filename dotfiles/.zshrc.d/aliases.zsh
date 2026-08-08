if (( $+commands[eza] )); then
    alias l='eza --group-directories-first'
    alias la='eza -a --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias lt='eza --tree --level=2 --group-directories-first'
else
    alias la='ls -A'
    alias ll='ls -alF'
fi

if (( $+commands[bat] )); then
    alias catp='bat --paging=never --style=plain'
    alias batl='bat --paging=always'
fi
