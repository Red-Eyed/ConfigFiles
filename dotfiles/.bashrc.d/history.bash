# shellcheck shell=bash

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000000
HISTFILESIZE=10000000
HISTTIMEFORMAT='%F %T '

shopt -s histappend
shopt -s cmdhist
shopt -s lithist
shopt -s checkwinsize

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\C-r": reverse-search-history'

history_sync='history -a; history -n'
case ";${PROMPT_COMMAND:-};" in
    *";$history_sync;"*) ;;
    *) PROMPT_COMMAND="$history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
unset history_sync
