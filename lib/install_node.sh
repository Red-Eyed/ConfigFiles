#!/usr/bin/env bash
set -ex
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

if ! command_exists nvm; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    # shellcheck source=/dev/null
    source "$HOME/.nvm/nvm.sh"
    nvm install --lts
else
    info "nvm is already installed"
fi
