#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo apt update
sudo apt install --yes \
    mc \
    tree \
    vim \
    git \
    git-lfs \
    etckeeper \
    zsh \
    keepassxc \
    htop \
    meld \
    ccache \
    p7zip-full \
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
    lsp-plugins \
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
    hardinfo \
    gnome-clocks \
    gnome-tweaks \
    icedtea-netx \
    python-nautilus \
    nautilus-gtkhash \
    stow \
    nmap \
    net-tools \
    lm-sensors \
    vainfo \
    vdpauinfo \
    mediainfo-gui \
    mediainfo \
    ffmpeg \
    ubuntu-restricted-extras \
    inxi \
    cpufrequtils \
    vlc \
    nvme-cli
