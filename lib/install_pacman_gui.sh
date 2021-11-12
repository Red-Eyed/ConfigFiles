#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo pacman -Suy --needed --noconfirm \
    meld \
    qtcreator \
    sqlitebrowser \
    gparted \
    grub-customizer \
    hardinfo \
    gnome-software \
    gnome-tweaks

sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap
