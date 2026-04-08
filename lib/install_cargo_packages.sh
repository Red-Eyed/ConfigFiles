#!/usr/bin/env bash

# allow errors
set +e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

if command_exists rustup; then
    info "Rustup is already installed. Running update..."
    rustup update
else
    info "Rustup not found. Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

export PATH="$HOME/.cargo/bin:$PATH"
export RUST_BACKTRACE=1


cargo_install() {
    command_exists cargo || die "cargo not found in PATH"
    # Always use --locked to enforce Cargo.lock
    cargo install --locked "$@"
}


# add sccache first so subsequent builds can use it as a compiler cache
cargo_install sccache

if command_exists sccache; then
    RUSTC_WRAPPER="$(command -v sccache)"
    export RUSTC_WRAPPER
    info "Using sccache for Rust builds: $RUSTC_WRAPPER"
else
    warn "sccache not found, building without compiler cache"
fi

cargo_install ripgrep     # fast recursive grep alternative
cargo_install fd-find     # user-friendly alternative to find
cargo_install bat         # enhanced cat with syntax highlighting
cargo_install eza         # modern ls replacement with Git integration
cargo_install du-dust     # intuitive disk usage analyzer
cargo_install hyperfine   # command-line benchmarking tool
cargo_install trashy      # safer alternative to rm

# Install fish shell from source
cargo_install --git https://github.com/fish-shell/fish-shell --tag 4.1.0
