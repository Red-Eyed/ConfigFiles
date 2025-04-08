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
cargo install --locked yazi-fm

# Install yazi-cli (terminal frontend for yazi-fm)
cargo install --locked yazi-cli

# Install ripgrep (fast recursive grep alternative)
cargo install --locked ripgrep

# Install fd (user-friendly alternative to `find`)
cargo install --locked fd-find

# Install bat (enhanced `cat` with syntax highlighting)
cargo install --locked bat

# Install exa (modern `ls` replacement with Git integration)
cargo install --locked exa

# Install dust (intuitive disk usage analyzer)
cargo install --locked du-dust

# Install hyperfine (command-line benchmarking tool)
cargo install --locked hyperfine

# Install tokei (code statistics generator)
cargo install --locked tokei
