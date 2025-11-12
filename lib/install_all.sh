#!/usr/bin/env bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

./install_all_no_root.sh
./install_apt_headless.sh

