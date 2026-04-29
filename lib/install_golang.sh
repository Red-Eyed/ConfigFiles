#!/usr/bin/env bash
#
# Installs the latest stable Go toolchain into "$HOME/.local/go" without
# requiring root access. Supports Linux and macOS on amd64 and arm64.

set -euo pipefail

log() {
    echo "[install_golang] $*"
}

log "Fetching latest Go version..."
GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n 1)

case "$(uname -s)" in
    Darwin)
        GO_OS="darwin"
        ;;
    Linux)
        GO_OS="linux"
        ;;
    *)
        echo "Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    arm64 | aarch64)
        GO_ARCH="arm64"
        ;;
    x86_64 | amd64)
        GO_ARCH="amd64"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

ARCHIVE="${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
TMP_ARCHIVE=$(mktemp "${TMPDIR:-/tmp}/go.XXXXXX")
trap 'rm -f "$TMP_ARCHIVE"' EXIT

log "Detected platform: ${GO_OS}-${GO_ARCH}"
log "Downloading ${ARCHIVE}..."
curl -fsSL "https://go.dev/dl/${ARCHIVE}" -o "$TMP_ARCHIVE"

log "Removing previous install at $HOME/.local/go..."
rm -rf "$HOME/.local/go"
mkdir -p "$HOME/.local"

log "Extracting Go to $HOME/.local/go..."
tar -C "$HOME/.local" -xzf "$TMP_ARCHIVE"

log "Done. Go installed at $HOME/.local/go"
