#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

./install_apt_headless.sh
./install_no_root.sh
