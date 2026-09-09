#!/bin/sh

show_image() {
    viu --static -- "$1" || return $?
    printf 'Press Enter to return to MC '
    read -r _reply || :
}

# The subshell owns the buffer and its cleanup; callers cannot forget restoration.
with_preview_screen() (
    # smcup/rmcup switch buffers without adding the preview to shell scrollback.
    # Resolve both before switching, so unsupported terminals keep normal viewing.
    if enter_screen=$(tput smcup 2>/dev/null) &&
        leave_screen=$(tput rmcup 2>/dev/null); then
        trap 'printf "%s" "$leave_screen"' 0
        # Signal exits also run the exit trap, including while awaiting Enter.
        trap 'exit 129' HUP
        trap 'exit 130' INT
        trap 'exit 143' TERM
        printf '%s' "$enter_screen"
    fi

    "$@"
)

file=$1
# A relative name starting with '-' must remain a filename for every viewer.
case "$file" in
    /*) ;;
    *) file="./$file" ;;
esac

# Graphics need direct terminal output, not MC's internal text-viewer pipe.
if [ -t 1 ] && command -v viu >/dev/null 2>&1; then
    with_preview_screen show_image "$file"
    preview_status=$?
    case "$preview_status" in
        0) exit 0 ;;
        # Cancelling a preview should return to MC, not start another viewer.
        129|130|143) exit "$preview_status" ;;
    esac
fi

# mc -v reuses this association and would recurse when image decoding fails.
exec less -f -- "$file"
