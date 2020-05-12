#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo apt update
sudo apt install --yes \
    mc \
    vim \
    git \
    git-lfs \
    etckeeper \
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
    qbittorrent \
    pulseeffects \
    telegram-desktop \
    earlyoom \
    network-manager-openvpn \
    sqlitebrowser \
    openssh-server \
    android-tools-adb \
    gparted \
    mtp-tools \
    ntfs-3g \
    cifs-utils \
    nfs-common \
    sshfs \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    icedtea-netx \
    nmap \
    python-nautilus \
    stow
