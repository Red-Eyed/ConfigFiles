#!/usr/bin/env bash

# allow errors
set +e
cd $(dirname $(readlink -f $0))
. header.sh

# install cargo
if command -v rustup >/dev/null 2>&1; then
    echo "Rustup is already installed. Running update..."
    rustup update
else
    echo "Rustup not found. Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

export PATH=$HOME/.cargo/bin:$PATH
export RUST_BACKTRACE=1


cargo_install() {
    if ! command -v cargo >/dev/null; then
        echo "❌ cargo not found in PATH" >&2
        return 1
    fi

    # Always use --locked to enforce Cargo.lock
    cargo install --locked "$@"
}


# add sccache
cargo_install sccache

# Use sccache if available
if command -v sccache >/dev/null; then
    export RUSTC_WRAPPER="$(command -v sccache)"
    echo "✅ Using sccache for Rust builds: $RUSTC_WRAPPER"
else
    echo "⚠️ sccache not found, building without compiler cache"
fi

# Install ripgrep (fast recursive grep alternative)
cargo_install ripgrep

# Install fd (user-friendly alternative to `find`)
cargo_install fd-find

# Install bat (enhanced `cat` with syntax highlighting)
cargo_install bat

# Install exa (modern `ls` replacement with Git integration)
cargo_install exa

# Install dust (intuitive disk usage analyzer)
cargo_install du-dust

# Install hyperfine (command-line benchmarking tool)
cargo_install hyperfine


# Install fish shell
cargo_install --git https://github.com/fish-shell/fish-shell --tag 4.1.0

# safer alternative to rm
cargo_install trashy
