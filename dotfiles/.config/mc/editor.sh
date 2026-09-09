#!/bin/sh

file=$1
case "$file" in
    /*) ;;
    *) file="./$file" ;;
esac

if command -v micro >/dev/null 2>&1; then
    exec micro "$file"
fi

exec mcedit -- "$file"
