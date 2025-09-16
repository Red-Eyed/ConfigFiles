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
    tmux
    ncdu
    ccache
    zstd
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
    llvm
    openssh-server
    sshfs
    nmap
    net-tools
    inxi
    keychain
    sysfsutils
"

for pkg in $packages;
do
    sudo apt-get install --ignore-missing --yes $pkg
done
