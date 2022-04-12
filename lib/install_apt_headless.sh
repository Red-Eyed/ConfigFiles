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
    htop \
    tmux \
    ncdu \
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
    earlyoom \
    openssh-server \
    android-tools-adb \
    mtp-tools \
    ntfs-3g \
    cifs-utils \
    nfs-common \
    sshfs \
    icedtea-netx \
    stow \
    nmap \
    net-tools \
    lm-sensors \
    vainfo \
    vdpauinfo \
    mediainfo \
    ffmpeg \
    ubuntu-restricted-extras \
    inxi \
    cpufrequtils \
    nvme-cli \
    libnss-mdns \
    python3-pip
