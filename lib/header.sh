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
