#!/usr/bin/env bash
set -ex
cd $(dirname $(readlink -f $0))
. header.sh

if [ ! command -v nvm ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    source $HOME/.nvm/nvm.sh
    nvm install --lts
else
    echo "nvm is already installed"
fi
