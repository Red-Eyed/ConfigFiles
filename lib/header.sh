#!/usr/bin/env bash

echo "Running $0"

# ── predicates ────────────────────────────────────────────────────────────────

file_exists()    { [[ -f "$1" ]]; }
dir_exists()     { [[ -d "$1" ]]; }
command_exists() { command -v "$1" >/dev/null 2>&1; }
is_root()        { [[ "$EUID" -eq 0 ]]; }

# ── logging ───────────────────────────────────────────────────────────────────

info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; }
die()   { error "$*"; exit 1; }

# ── download ──────────────────────────────────────────────────────────────────

# download <url> <dest>
download() { curl --proto '=https' --tlsv1.2 -fsSL "$1" -o "$2"; }

# ── git pinning ───────────────────────────────────────────────────────────────

# Clone a repo and check out the newest commit that is at least DAYS old.
# Skips the clone if DEST already exists.
# Usage: clone_pinned_repo <url> <dest> <days>
clone_pinned_repo() {
    local url="$1" dest="$2" days="$3"
    if ! dir_exists "$dest"; then
        git clone --quiet "$url" "$dest"
    fi
    local commit
    commit=$(git -C "$dest" log --before="${days} days ago" -1 --format="%H")
    [[ -n "$commit" ]] || die "No commit older than ${days} days found in $url"
    git -C "$dest" checkout --quiet "$commit"
}
