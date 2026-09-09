#!/bin/sh

file=$1
case "$file" in
    /*) ;;
    *) file="./$file" ;;
esac

# Terminal graphics must not be piped through MC's text viewer.
if [ -t 1 ] && command -v viu >/dev/null 2>&1 && viu --static -- "$file"; then
    printf 'Press Enter to return to MC '
    read -r _reply
    exit 0
fi

exec mc -v -- "$file"
