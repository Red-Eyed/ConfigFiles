#!/bin/bash
cd $(dirname $(readlink -f $0))

sudo apt-get update
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

packages="
    ripgrep
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
    libc++-dev
    libc++1
    libc++abi-dev
    libc++abi1
    libclang-dev
    libclang1
    liblldb-dev
    libllvm-ocaml-dev
    libomp-dev
    libomp5 
    lld
    lldb
    llvm-dev
    llvm-runtime
    llvm python3-clang
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
    mediainfo
    ffmpeg
    inxi
    cpufrequtils
    nvme-cli
    python3-pip
    python3-virtualenv
    keychain
    libfuse2
    sysfsutils
"

for pkg in $packages;
do
    sudo apt-get install --ignore-missing --yes $pkg
done
