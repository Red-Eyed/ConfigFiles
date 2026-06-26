#!/usr/bin/env bash
# Bash port of the bira-ascii zsh theme.
# Prompt: +--user@host ~/path <branch*>
#         +- $

_bira_git_info() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
    local dirty=''
    git diff --quiet HEAD 2>/dev/null || dirty='*'
    printf '%s' "${branch}${dirty}"
}

_bira_prompt() {
    local git_part=''
    local branch
    branch=$(_bira_git_info)
    if [[ -n "$branch" ]]; then
        git_part="\[\e[0;33m\]<${branch}> \[\e[0m\]"
    fi

    local user_color
    if [[ $EUID -eq 0 ]]; then
        user_color='\[\e[1;31m\]'
    else
        user_color='\[\e[1;32m\]'
    fi

    PS1="+--${user_color}\u@\h\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\] ${git_part}
+- \$ "
}

PROMPT_COMMAND="_bira_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
