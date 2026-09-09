#!/usr/bin/env bash
#
# Reuses an existing Go toolchain or installs the latest stable release into
# "$HOME/.local/go". Supports Linux and macOS on amd64 and arm64 without root.

set -euo pipefail

log() {
    echo "[install_golang] $*"
}

INSTALL_DIR="$HOME/.local/go"

installed_go_version() {
    local go_binary
    for go_binary in "$INSTALL_DIR/bin/go" "$(command -v go || true)"; do
        [[ -x "$go_binary" ]] || continue
        # Inspect the bundled toolchain without downloading a project-selected version.
        if GOTOOLCHAIN=local "$go_binary" version 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

if CURRENT_GO_VERSION=$(installed_go_version); then
    log "Already installed: ${CURRENT_GO_VERSION}"
    exit 0
fi

log "Fetching latest Go version..."
GO_VERSION=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n 1)

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

log "Removing previous install at ${INSTALL_DIR}..."
rm -rf "$INSTALL_DIR"
mkdir -p "$HOME/.local"

log "Extracting Go to ${INSTALL_DIR}..."
tar -C "$HOME/.local" -xzf "$TMP_ARCHIVE"

log "Done. Go installed at ${INSTALL_DIR}"
