#!/usr/bin/env bash

# allow errors
set +e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

if command_exists rustup; then
    info "Rustup is already installed. Running update..."
    rustup update
else
    info "Rustup not found. Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
