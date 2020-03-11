#!/bin/bash
set -e

if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi

cd $(dirname $(readlink -f $0))

sudo apt update
sudo apt install --yes \
    mc \
    vim \
    git \
    zsh \
    htop \
    meld \
    ccache \
    pigz \
    patool \
    build-essential \
    cmake \
    ninja-build \
    g++ \
    clang \
    clang-format \
    lldb \
    neofetch \
    qtcreator \
    earlyoom \
    qbittorrent \
    network-manager-openvpn \
    sqlitebrowser \
    ksystemlog \
    krita \
    openssh-server \
    libreoffice \
    android-tools-adbd \
    gparted \
    seahorse \
    mtp-tools \
    ntfs-3g \
    cifs-utils \
    nfs-common \
    sshfs \
    filezilla \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install com.anydesk.Anydesk

. ./install_snap.sh
. ./install_python.sh
. ./install_oh-my-zsh.sh

if [[ -x "$(command -v balooctl)" ]]; then
    balooctl stop
    balooctl disable
fi

echo "###################################"
echo "Please, log out to apply changes!"
