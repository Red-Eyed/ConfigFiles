#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo apt update
sudo apt full-upgrade --yes
sudo apt autoremove --yes
sudo apt autoclean --yes

packages="
    keepassxc
    meld
    qtcreator
    qbittorrent
    pulseeffects
    lsp-plugins
    telegram-desktop
    network-manager-openvpn
    network-manager-openvpn-gnome
    sqlitebrowser
    gparted
    hardinfo
    gnome-clocks
    gnome-tweaks
    python-nautilus
    nautilus-gtkhash
    mediainfo-gui
    vlc
    gamemode
"

for pkg in $packages;
do
    sudo apt-get install --ignore-missing --yes $pkg
done

rm -f ~/Downloads/zoom_amd64.deb
wget -nc https://zoom.us/client/latest/zoom_amd64.deb -P ~/Downloads
sudo apt install -f -y ~/Downloads/zoom_amd64.deb

rm -f ~/Downloads/teamviewer_amd64.deb
wget -nc https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -P ~/Downloads
sudo apt install -f -y ~/Downloads/teamviewer_amd64.deb
