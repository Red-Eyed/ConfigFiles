#!/usr/bin/env bash

set -e
cd $(dirname $(readlink -f $0))
. header.sh

export PATH=$HOME/.cargo/bin:$PATH

if command -v rustup >/dev/null 2>&1; then
    echo "Rustup is already installed. Running update..."
    rustup update
else
    echo "Rustup not found. Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Install yazi-fm (core file manager engine)
cargo install yazi-fm

# Install yazi-cli (terminal frontend for yazi-fm)
cargo install yazi-cli

# Install ripgrep (fast recursive grep alternative)
cargo install ripgrep

# Install fd (user-friendly alternative to `find`)
cargo install fd-find

# Install bat (enhanced `cat` with syntax highlighting)
cargo install bat

# Install exa (modern `ls` replacement with Git integration)
cargo install exa

# Install dust (intuitive disk usage analyzer)
cargo install du-dust

# Install hyperfine (command-line benchmarking tool)
cargo install hyperfine

# Install tokei (code statistics generator)
cargo install tokei

# Install fish shell
cargo install --git https://github.com/fish-shell/fish-shell --tag 4.0.0

cargo install coreutils

# safer alternative to rm
cargo install trashy

# nvtop like
cargo install nviwatch
