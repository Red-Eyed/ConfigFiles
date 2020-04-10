#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo pacman -Suy --needed --noconfirm \
    base-devel \
    gcc-fortran \
    intel-tbb \
    cblas \
    lapack \
    lapacke \
    eigen \
    strace \
    yay \
    mc \
    vim \
    git \
    git-lfs \
    zsh \
    htop \
    meld \
    ccache \
    pigz \
    cmake \
    ninja \
    clang \
    lldb \
    fwupd \
    ethtool \
    neofetch \
    qtcreator \
    sqlitebrowser \
    android-tools \
    gparted \
    grub-customizer \
    ntfs-3g \
    cifs-utils \
    sshfs \
    openssh \
    snapd \
    flatpak \
    gtkhash-nautilus \
    hardinfo \
    tlpui \
    gnome-software \
    gnome-tweaks \
    icedtea-web \
    nmap \
    stow

sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap
