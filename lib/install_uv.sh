#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "uv is already installed at $(command -v uv)"
fi

uv self update
