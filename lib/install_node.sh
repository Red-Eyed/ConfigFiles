#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source $HOME/.nvm/nvm.sh
nvm install --lts
