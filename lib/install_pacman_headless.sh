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
    tmux \
    htop \
    ccache \
    pigz \
    cmake \
    ninja \
    clang \
    lldb \
    fwupd \
    ethtool \
    neofetch \
    android-tools \
    ntfs-3g \
    cifs-utils \
    sshfs \
    openssh \
    snapd \
    flatpak \
    gtkhash-nautilus \
    tlpui \
    icedtea-web \
    nmap \
    stow \
    lrzip \
    p7zip \
    squashfs-tools \
    unace \
    unrar

sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap
