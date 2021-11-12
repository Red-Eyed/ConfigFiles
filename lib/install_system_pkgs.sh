#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

pkg_managers="pacman apt rpm-ostree"

if [ "$1" == "gui" ]; then
    modes="console gui"
else
    modes="console"
fi

for cmd in $pkg_managers; do
    if [ x$(command -v $cmd) != x ]; then
        for mode in $modesl do
            ./install_$cmd_$mode.sh
            break
        done
    fi
done
