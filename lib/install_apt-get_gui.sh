#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

sudo apt-get install --yes \
    keepassxc \
    meld \
    qtcreator \
    qbittorrent \
    pulseeffects \
    lsp-plugins \
    telegram-desktop \
    network-manager-openvpn \
    network-manager-openvpn-gnome \
    sqlitebrowser \
    gparted \
    hardinfo \
    gnome-clocks \
    gnome-tweaks \
    python-nautilus \
    nautilus-gtkhash \
    mediainfo-gui \
    vlc \
    gamemode

rm -f ~/Downloads/zoom_amd64.deb
wget -nc https://zoom.us/client/latest/zoom_amd64.deb -P ~/Downloads
sudo apt install -f -y ~/Downloads/zoom_amd64.deb

rm -f ~/Downloads/teamviewer_amd64.deb
wget -nc https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -P ~/Downloads
sudo apt install -f -y ~/Downloads/teamviewer_amd64.deb
