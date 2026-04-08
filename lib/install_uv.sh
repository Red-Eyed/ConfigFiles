#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

export PATH="$HOME/.local/bin:$PATH"

if ! command_exists uv; then
    if ! curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | sh; then
        warn "Primary install failed, falling back to direct GitHub release..."
        UV_VERSION=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        curl --proto '=https' --tlsv1.2 -LsSf "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-installer.sh" | sh
    fi
else
    info "uv is already installed at $(command -v uv)"
fi

uv self update
