#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

SKEL_DIR="${SKEL_DIR:-/etc/skel}"
SKEL_BACKUP_DIR="${SKEL_BACKUP_DIR:-/opt/configfiles/skel-backups}"
SKEL_STATE_DIR="${SKEL_STATE_DIR:-/opt/configfiles/skel-state}"
temporary_file=

require_safe_directories() {
    local variable_name directory

    for variable_name in SKEL_DIR SKEL_BACKUP_DIR SKEL_STATE_DIR; do
        directory="${!variable_name}"
        [[ "$directory" == /* ]] || die "${variable_name} must be an absolute path"
        [[ "$directory" != / ]] || die "${variable_name} cannot be /"
    done

    [[ "$SKEL_BACKUP_DIR" != "$SKEL_DIR" ]] ||
        die "SKEL_BACKUP_DIR and SKEL_DIR must differ"
    [[ "$SKEL_BACKUP_DIR" != "$SKEL_DIR/"* ]] ||
        die "SKEL_BACKUP_DIR cannot be inside SKEL_DIR"
    [[ "$SKEL_STATE_DIR" != "$SKEL_DIR" ]] ||
        die "SKEL_STATE_DIR and SKEL_DIR must differ"
    [[ "$SKEL_STATE_DIR" != "$SKEL_DIR/"* ]] ||
        die "SKEL_STATE_DIR cannot be inside SKEL_DIR"
    [[ "$SKEL_STATE_DIR" != "$SKEL_BACKUP_DIR" ]] ||
        die "SKEL_STATE_DIR and SKEL_BACKUP_DIR must differ"
}

cleanup_temporary_files() {
    if [[ -n "$temporary_file" ]]; then
        sudo rm -f -- "$temporary_file"
    fi
}

ensure_parent_directory() {
    local path="$1"
    local parent="${path%/*}"

    if [[ ! -d "$parent" ]]; then
        sudo install -d -m 0755 "$parent"
    fi
}

atomic_install() {
    local source="$1"
    local target="$2"

    ensure_parent_directory "$target"
    temporary_file=$(sudo mktemp "${target}.configfiles.XXXXXX")
    sudo install -m 0644 "$source" "$temporary_file"
    sudo mv -f -- "$temporary_file" "$target"
    temporary_file=
}

backup_original() {
    local target="$1"
    local backup="$2"

    if [[ -e "$backup" || -L "$backup" ]]; then
        return
    fi

    ensure_parent_directory "$backup"
    info "Backing up ${target} to ${backup}"
    sudo cp -pP "$target" "$backup"
}

install_skel_file() {
    local source="$1"
    local relative="$2"
    local target="$SKEL_DIR/$relative"
    local backup="$SKEL_BACKUP_DIR/$relative"
    local state="$SKEL_STATE_DIR/$relative"

    [[ -f "$source" ]] || die "Skeleton source does not exist: ${source}"

    if [[ -d "$target" && ! -L "$target" ]]; then
        die "Cannot replace directory with skeleton file: ${target}"
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ ! -L "$target" ]] && cmp -s "$source" "$target"; then
            atomic_install "$source" "$state"
            return
        fi

        if [[ -f "$state" ]]; then
            if ! cmp -s "$target" "$state"; then
                warn "Preserving locally modified skeleton file: ${target}"
                return
            fi
        else
            backup_original "$target" "$backup"
        fi
    fi

    info "Installing skeleton file: ${target}"
    atomic_install "$source" "$target"
    atomic_install "$source" "$state"
}

install_skel_tree() {
    local source_directory="$1"
    local target_directory="$2"
    local source relative

    [[ -d "$source_directory" ]] || die "Skeleton source directory does not exist: ${source_directory}"

    while IFS= read -r -d '' source; do
        relative="${source#"$source_directory/"}"
        install_skel_file "$source" "$target_directory/$relative"
    done < <(find "$source_directory" -type f -print0)
}

trap cleanup_temporary_files EXIT
require_safe_directories

install_skel_file "$ROOT_DIR/lib/skel/.profile" .profile
install_skel_file "$ROOT_DIR/lib/skel/.bash_profile" .bash_profile
install_skel_file "$ROOT_DIR/lib/skel/.bashrc" .bashrc
install_skel_file "$ROOT_DIR/lib/skel/.zshrc" .zshrc
install_skel_file "$ROOT_DIR/dotfiles/.posixrc" .posixrc
install_skel_tree "$ROOT_DIR/dotfiles/.bashrc.d" .bashrc.d
install_skel_tree "$ROOT_DIR/dotfiles/.zshrc.d" .zshrc.d
install_skel_file \
    "$ROOT_DIR/dotfiles/.config/fish/config.fish" \
    .config/fish/config.fish
