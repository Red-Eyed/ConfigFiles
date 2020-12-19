#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

if [ x$(command -v $snap) != x ]; then
    exit 0
fi

sudo snap install pycharm-professional --classic
sudo snap install pycharm-community --classic
sudo snap install code --classic
sudo snap install snap-store


sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap
