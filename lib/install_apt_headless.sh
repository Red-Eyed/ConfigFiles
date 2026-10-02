#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit

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
    7zip
)

for package in "${packages[@]}"; do
    if ! sudo apt-get install --yes "$package"; then
        printf 'Skipping failed package: %s\n' "$package" >&2
    fi
done
