#!/usr/bin/env bash
set -eo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    info "Installing nvm"
    curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
    info "nvm is already installed at $NVM_DIR"
fi

# NVM is a shell function, so each installer shell must load it before checking Node.
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh" --no-use

if installed_lts=$(nvm version 'lts/*' 2>/dev/null); then
    info "Node LTS $installed_lts is already installed"
else
    info "Installing Node LTS"
    nvm install --lts
fi
