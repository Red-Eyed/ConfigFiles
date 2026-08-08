# shellcheck shell=bash

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export OSH="$HOME/.oh-my-bash"

# shellcheck disable=SC2034
OSH_THEME="bira-ascii"

# shellcheck disable=SC2034
DISABLE_AUTO_UPDATE="true"

# shellcheck disable=SC2034
CASE_SENSITIVE="true"

# shellcheck disable=SC2034
HIST_STAMPS="yyyy/mm/dd"

# shellcheck disable=SC2034
plugins=(
    git
    colored-man-pages
)

# shellcheck source=/dev/null
[[ -f "$OSH/oh-my-bash.sh" ]] && source "$OSH/oh-my-bash.sh"

# ── extract (OMZ plugin equivalent) ──────────────────────────────────────────

extract() {
    if [[ ! -f "$1" ]]; then echo "'$1' is not a valid file"; return 1; fi
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.zip)     unzip "$1" ;;
        *.7z)      7z x "$1" ;;
        *.xz)      xz --decompress "$1" ;;
        *.zst)     zstd --decompress "$1" ;;
        *.rar)     unrar x "$1" ;;
        *.Z)       uncompress "$1" ;;
        *)         echo "'$1' cannot be extracted" ;;
    esac
}

# ── rsync aliases (OMZ plugin equivalent) ─────────────────────────────────────

alias rsync-copy="rsync -avz --progress -h"
alias rsync-move="rsync -avz --progress -h --remove-source-files"
alias rsync-update="rsync -avzu --progress -h"
alias rsync-synchronize="rsync -avzu --delete --progress -h"

# ── environment ───────────────────────────────────────────────────────────────

export LANG=en_US.UTF-8
export EDITOR='micro'

# ── shared config ─────────────────────────────────────────────────────────────

# shellcheck source=/dev/null
[[ -f "$HOME/.posixrc" ]] && source "$HOME/.posixrc"

# ── interactive modules ───────────────────────────────────────────────────────

if [[ -d "$HOME/.bashrc.d" ]]; then
    for bash_config in "$HOME"/.bashrc.d/*.bash; do
        # shellcheck source=/dev/null
        [[ -r "$bash_config" ]] && source "$bash_config"
    done
    unset bash_config
fi
