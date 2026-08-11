#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

MANAGED_BIN_DIR="${MANAGED_BIN_DIR:-/opt/configfiles/bin}"
GLOBAL_BIN_DIR="${GLOBAL_BIN_DIR:-/usr/local/bin}"

require_safe_directories() {
    [[ "$MANAGED_BIN_DIR" == /* ]] || die "MANAGED_BIN_DIR must be an absolute path"
    [[ "$GLOBAL_BIN_DIR" == /* ]] || die "GLOBAL_BIN_DIR must be an absolute path"
    [[ "$MANAGED_BIN_DIR" != / ]] || die "MANAGED_BIN_DIR cannot be /"
    [[ "$GLOBAL_BIN_DIR" != "$MANAGED_BIN_DIR" ]] ||
        die "MANAGED_BIN_DIR and GLOBAL_BIN_DIR must differ"
    [[ "$GLOBAL_BIN_DIR" != "$MANAGED_BIN_DIR/"* ]] ||
        die "MANAGED_BIN_DIR cannot contain GLOBAL_BIN_DIR"
}

remove_managed_links() {
    local global_tool target

    [[ -d "$GLOBAL_BIN_DIR" ]] || return

    while IFS= read -r -d '' global_tool; do
        if ! target=$(readlink "$global_tool"); then
            warn "Skipping unreadable symlink: ${global_tool}"
            continue
        fi

        if [[ "$target" == "$MANAGED_BIN_DIR/"* ]]; then
            info "Removing managed link: ${global_tool}"
            sudo rm -- "$global_tool"
        fi
    done < <(
        find "$GLOBAL_BIN_DIR" -mindepth 1 -maxdepth 1 -type l -print0
    )
}

remove_managed_copies() {
    local managed_root="${MANAGED_BIN_DIR%/bin}"

    if [[ ! -d "$MANAGED_BIN_DIR" ]]; then
        info "No managed tool directory found at ${MANAGED_BIN_DIR}"
        return
    fi

    # This directory is exclusively owned by install_global_tools.sh.
    info "Removing managed tool directory: ${MANAGED_BIN_DIR}"
    sudo rm -r -- "$MANAGED_BIN_DIR"

    if [[ "$managed_root" != "$MANAGED_BIN_DIR" ]]; then
        sudo rmdir -- "$managed_root" 2>/dev/null || true
    fi
}

require_safe_directories
remove_managed_links
remove_managed_copies
