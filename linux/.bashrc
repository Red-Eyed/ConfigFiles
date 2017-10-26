# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

source ~/.bashrc_work

NCPU="$(getconf _NPROCESSORS_ONLN 2> /dev/null)"
export MAKEFLAGS=" -j$NCPU "

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Setting default editor
export EDITOR=/usr/bin/vim
color_prompt=yes

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Set prompt
export PS1="\
\[\033[48;5;18m\]\u:\[$(tput sgr0)\]\
\[\033[48;5;18m\]\h\[$(tput sgr0)\] \
\[\033[38;5;184m\]\w\[$(tput sgr0)\] \
\[\033[38;5;196m\]\T : \[$(tput sgr0)\] \
\[\033[38;5;196m\]\d\[$(tput sgr0)\]\
\n[\$?]-> \[$(tput sgr0)\]"

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
alias sudo='sudo '
# alias date='date  +"%Y/%m/%d %H:%M" '

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls-color='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
if command -v ls-color > /dev/null 2>&1; then
    alias ls='ls-color --time-style=long-iso -h'
else
    alias ls='ls --time-style=long-iso -h'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias xclip='xclip -selection clipboard'
alias getpwd='pwd | xclip'
alias ip='ip -c'
alias rsync='rsync --info=progress2 '
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


## HISTORY CONFIG ##

# don't put duplicate lines or lines starting with space in the history.
# https://askubuntu.com/questions/15926/how-to-avoid-duplicate-entries-in-bash-history
export HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history

# Sync history alias
alias sync_hist='history -a; history -c; history -r'

# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
#PROMPT_COMMAND="sync_hist; $PROMPT_COMMAND"



# Pulseaudio stereo to mono:
# https://askubuntu.com/questions/17791/can-i-downmix-stereo-audio-to-mono 
# pacmd list-sinks | grep name:
# pacmd load-module module-remap-sink sink_name=mono master=<name_of_audiosink_given_by_previous_command> channels=2 channel_map=mono,mono


