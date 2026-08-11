#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-$HOME/.local/bin}"
CARGO_BIN_DIR="${CARGO_BIN_DIR:-$HOME/.cargo/bin}"
BUN_BIN_DIR="${BUN_BIN_DIR:-$HOME/.bun/bin}"
MANAGED_BIN_DIR="${MANAGED_BIN_DIR:-/opt/configfiles/bin}"
GLOBAL_BIN_DIR="${GLOBAL_BIN_DIR:-/usr/local/bin}"

require_absolute_directory() {
    local directory="$1"
    local variable_name="$2"

    [[ "$directory" == /* ]] || die "${variable_name} must be an absolute path"
}

ensure_directory() {
    local directory="$1"

    if [[ ! -d "$directory" ]]; then
        sudo install -d -m 0755 "$directory"
    fi
}

link_tool() {
    local managed_tool="$1"
    local global_tool="$2"
    local current_target

    if [[ -L "$global_tool" ]]; then
        if ! current_target=$(readlink -f "$global_tool"); then
            warn "Skipping ${global_tool}: it is a broken symlink"
            return
        fi

        if [[ "$current_target" != "$managed_tool" ]]; then
            warn "Skipping ${global_tool}: it links to ${current_target}"
            return
        fi

        return
    fi

    if [[ -e "$global_tool" ]] && ! cmp -s "$global_tool" "$managed_tool"; then
        warn "Skipping ${global_tool}: an unrelated file already exists"
        return
    fi

    info "Linking ${global_tool} to ${managed_tool}"
    sudo ln -sfn "$managed_tool" "$global_tool"
}

publish_tool() {
    local source="$1"
    local name="${source##*/}"
    local managed_tool="$MANAGED_BIN_DIR/$name"
    local global_tool="$GLOBAL_BIN_DIR/$name"

    if [[ ! -x "$source" ]]; then
        warn "Skipping ${name}: ${source} is not installed"
        return
    fi

    info "Copying ${source} to ${managed_tool}"
    sudo install -m 0755 "$source" "$managed_tool"
    link_tool "$managed_tool" "$global_tool"
}

discover_directory_tools() {
    local directory="$1"
    local candidate canonical_directory resolved

    if [[ ! -d "$directory" ]]; then
        warn "Skipping missing tool directory: ${directory}"
        return
    fi

    canonical_directory=$(readlink -f "$directory")

    while IFS= read -r -d '' candidate; do
        if [[ -L "$candidate" ]]; then
            if ! resolved=$(readlink -f "$candidate"); then
                warn "Skipping broken symlink: ${candidate}"
                continue
            fi

            # External symlinks can depend on user-writable runtimes or environments.
            if [[ "$resolved" != "$canonical_directory/"* ]]; then
                warn "Skipping externally managed symlink: ${candidate}"
                continue
            fi
        fi

        publish_tool "$candidate"
    done < <(
        find "$directory" -mindepth 1 -maxdepth 1 \
            \( -type f -o -type l \) -perm -u+x -print0
    )
}

discover_cargo_tools() {
    local cargo="$CARGO_BIN_DIR/cargo"
    local installed line

    if [[ ! -x "$cargo" ]]; then
        warn "Skipping Cargo tools: ${cargo} is not installed"
        return
    fi

    if ! installed=$("$cargo" install --list); then
        warn "Skipping Cargo tools: unable to read Cargo installation metadata"
        return
    fi

    while IFS= read -r line; do
        [[ "$line" == "    "* ]] || continue
        publish_tool "$CARGO_BIN_DIR/${line#    }"
    done <<<"$installed"
}

require_absolute_directory "$LOCAL_BIN_DIR" LOCAL_BIN_DIR
require_absolute_directory "$CARGO_BIN_DIR" CARGO_BIN_DIR
require_absolute_directory "$BUN_BIN_DIR" BUN_BIN_DIR
require_absolute_directory "$MANAGED_BIN_DIR" MANAGED_BIN_DIR
require_absolute_directory "$GLOBAL_BIN_DIR" GLOBAL_BIN_DIR

ensure_directory "$MANAGED_BIN_DIR"
ensure_directory "$GLOBAL_BIN_DIR"

discover_directory_tools "$LOCAL_BIN_DIR"
discover_directory_tools "$BUN_BIN_DIR"
discover_cargo_tools
