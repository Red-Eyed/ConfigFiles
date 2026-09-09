#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit

# https://github.com/volitank/nala
# Nala is a front-end for libapt-pkg.
sudo apt-get install nala

packages=(
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
)

if apt-cache show 7zip >/dev/null 2>&1; then
    packages+=(7zip)
else
    packages+=(p7zip-full)
fi

sudo nala install "${packages[@]}"
