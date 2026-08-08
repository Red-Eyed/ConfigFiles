# shellcheck shell=bash

if command -v eza >/dev/null 2>&1; then
    alias l='eza --group-directories-first'
    alias la='eza -a --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias lt='eza --tree --level=2 --group-directories-first'
else
    alias la='ls -A'
    alias ll='ls -alF'
fi

if command -v bat >/dev/null 2>&1; then
    alias catp='bat --paging=never --style=plain'
    alias batl='bat --paging=always'
fi

if command -v trashy >/dev/null 2>&1; then
    alias rm='trashy'
    alias rmdir='trashy'
    alias trash='trashy'
fi
