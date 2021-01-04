#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

pkg_managers="pacman apt rpm-ostree"

for cmd in $pkg_managers; do
    if [ x$(command -v $cmd) != x ]; then
        ./install_$cmd.sh
        break
    fi
done
