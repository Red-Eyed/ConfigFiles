#!/bin/bash
cd $(dirname $(readlink -f $0))

sudo apt-get update
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

packages="
    mc
    tree
    vim
    git
    git-lfs
    etckeeper
    zsh
    htop
    tmux
    ncdu
    ccache
    p7zip-full
    pigz
    patool
    build-essential
    cmake
    ninja-build
    g++
    clang
    clang-format
    lldb
    neofetch
    earlyoom
    openssh-server
    android-tools-adb
    mtp-tools
    ntfs-3g
    cifs-utils
    nfs-common
    sshfs
    icedtea-netx
    stow
    nmap
    net-tools
    lm-sensors
    vainfo
    vdpauinfo
    mediainfo
    ffmpeg
    ubuntu-restricted-extras
    inxi
    cpufrequtils
    nvme-cli
    libnss-mdns
    python3-pip
    python3-virtualenv
    keychain
"

for pkg in $packages;
do
    sudo apt-get install --ignore-missing --yes $pkg
done