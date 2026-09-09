#!/bin/sh

helper=$1
shift

# Ask MC for its packaged handlers instead of assuming a distro-specific path.
handler_dir=$(LC_ALL=C mc --datadir-info | sed -n 's/^[[:space:]]*File extension handlers: *//p')
if [ -n "$handler_dir" ] && [ -f "$handler_dir/$helper.sh" ]; then
    exec sh "$handler_dir/$helper.sh" "$@"
fi

printf 'MC handler unavailable: %s\n' "$helper" >&2
exit 1
