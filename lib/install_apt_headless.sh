#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
. header.sh

sudo apt-get update
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

sudo apt-get install --yes \
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
    android-tools-adb \
    mtp-tools \
    sshfs \
    icedtea-netx \
    stow \
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
    python3-pip \
    python3-venv
