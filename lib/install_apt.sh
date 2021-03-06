#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo apt update
sudo apt full-upgrade --yes
sudo apt autoremove --yes
sudo apt autoclean --yes

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
    network-manager-openvpn-gnome \
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
    nvme-cli \
    libnss-mdns \
    gamemode

rm -f ~/Downloads/zoom_amd64.deb
wget -nc https://zoom.us/client/latest/zoom_amd64.deb -P ~/Downloads
sudo apt install -f -y ~/Downloads/zoom_amd64.deb

rm -f ~/Downloads/teamviewer_amd64.deb
wget -nc https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -P ~/Downloads
sudo apt install -f -y ~/Downloads/teamviewer_amd64.deb
