#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

pkg_managers="pacman apt rpm-ostree"

if [ "$1" == "gui" ]; then
    modes="headless gui"
else
    modes="headless"
fi

for cmd in $pkg_managers; do
    if [ x$(command -v $cmd) != x ]; then
        for mode in $modes; do
            ./install_${cmd}_${mode}.sh
            break
        done
    fi
done
