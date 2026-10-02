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
)

if apt-cache show 7zip >/dev/null 2>&1; then
    packages+=(7zip)
elif apt-cache show p7zip-full >/dev/null 2>&1; then
    packages+=(p7zip-full)
fi

available_packages=()
for package in "${packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
        available_packages+=("$package")
    else
        printf 'Skipping unavailable package: %s\n' "$package" >&2
    fi
done

if ((${#available_packages[@]})); then
    sudo apt-get install "${available_packages[@]}"
fi
