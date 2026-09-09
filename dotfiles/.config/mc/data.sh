#!/bin/sh

format=$1
file=$2
case "$file" in
    /*) ;;
    *) file="./$file" ;;
esac

within_preview_limit() {
    max_bytes=${MC_DATA_PREVIEW_MAX_BYTES:-67108864}
    case "$max_bytes" in
        *[!0-9]*|'') return 1 ;;
    esac

    size=$(stat -L -c %s -- "$file" 2>/dev/null) ||
        size=$(stat -L -f %z "$file" 2>/dev/null) || return 1
    [ "$size" -le "$max_bytes" ] 2>/dev/null
}

view_data() {
    case "$format" in
        json|jsonl)
            command -v jless >/dev/null 2>&1 || return 1
            jless --json --mode line -- "$file"
            ;;
        *)
            command -v tw >/dev/null 2>&1 || return 1
            tw --format "$format" -- "$file"
            ;;
    esac
}

# Both viewers load data into memory; the cutoff uses file size, not decoded size.
if [ -t 1 ] && within_preview_limit && view_data; then
    exit 0
fi

# mc -v would invoke this association again.
exec less -f -- "$file"
