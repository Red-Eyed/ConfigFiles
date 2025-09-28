#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

./install_dotfiles.sh
./install_uv.sh
./install_cargo_packages.sh
