#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if ! command_exists bun; then
    curl --proto '=https' --tlsv1.2 -fsSL https://bun.com/install | bash
else
    info "bun is already installed at $(command -v bun)"
fi
