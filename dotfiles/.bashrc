# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export OSH="$HOME/.oh-my-bash"

OSH_THEME="powerline-multiline"

DISABLE_AUTO_UPDATE="true"

CASE_SENSITIVE="true"

HIST_STAMPS="yyyy/mm/dd"

plugins=(
    git
    history
    colored-man-pages
    extract
    rsync
)

# shellcheck source=/dev/null
[[ -f "$OSH/oh-my-bash.sh" ]] && source "$OSH/oh-my-bash.sh"

# ── history ───────────────────────────────────────────────────────────────────

HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
HISTSIZE=10000000
HISTFILESIZE=10000000

# Arrow up/down searches history matching the current prefix (zsh-like behaviour)
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# ── environment ───────────────────────────────────────────────────────────────

export LANG=en_US.UTF-8
export EDITOR='micro'

# ── shared config ─────────────────────────────────────────────────────────────

[[ -f "$HOME/.posixrc" ]] && source "$HOME/.posixrc"
