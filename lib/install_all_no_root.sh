#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

./install_dotfiles.sh
./install_uv.sh
./install_golang.sh
./install_node.sh
./install_bun.sh
./install_cargo.sh
if ! ./install_cargo_packages.sh; then
    warn "Cargo CLI package installation failed; continuing without optional tools"
fi
