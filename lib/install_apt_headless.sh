#!/usr/bin/env bash
cd $(dirname $(readlink -f $0))

sudo apt-get update
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

packages="
    openssl
    pkg-config
    libssl-dev
    mc
    micro
    tree
    vim
    git
    git-lfs
    etckeeper
    zsh
    fish
    htop
    nvtop
    tmux
    ncdu
    ccache
    p7zip-full
    zstd
    pigz
    patool
    build-essential
    cmake
    ninja-build
    g++
    clang-format
    clang-tidy
    clang-tools
    clang
    clangd
    lld
    lldb
    llvm-dev
    llvm-runtime
    llvm python3-clang
    neofetch
    openssh-server
    mtp-tools
    ntfs-3g
    cifs-utils
    nfs-common
    sshfs
    icedtea-netx
    stow
    nmap
    net-tools
    mediainfo
    ffmpeg
    inxi
    cpufrequtils
    nvme-cli
    keychain
    libfuse2
    sysfsutils
"

for pkg in $packages;
do
    sudo apt-get install --ignore-missing --yes $pkg
done
