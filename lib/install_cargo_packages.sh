#!/usr/bin/env bash

# allow errors
set +e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

export PATH="$HOME/.cargo/bin:$PATH"
export RUST_BACKTRACE=1
export BINSTALL_DISABLE_TELEMETRY=true

install_binstall() {
    if command_exists cargo-binstall; then
        info "cargo-binstall is already installed"
        return
    fi

    info "Installing cargo-binstall from prebuilt release..."
    if curl -L --proto '=https' --tlsv1.2 -sSf \
        https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh |
        bash; then
        return
    fi

    die "Prebuilt cargo-binstall install failed"
}

install_cli_tool() {
    local crate="$1"
    local description="$2"

    command_exists cargo-binstall || die "cargo-binstall not found in PATH"

    info "Installing ${crate}: ${description}"
    cargo binstall --no-confirm --disable-strategies compile "$crate"
}

install_binstall

# add sccache first so subsequent builds can use it as a compiler cache
install_cli_tool sccache "Rust compiler cache"

if command_exists sccache; then
    RUSTC_WRAPPER="$(command -v sccache)"
    export RUSTC_WRAPPER
    info "Using sccache for Rust builds: $RUSTC_WRAPPER"
else
    warn "sccache not found, building without compiler cache"
fi

install_cli_tool ripgrep "fast recursive grep alternative"
install_cli_tool fd-find "user-friendly alternative to find"
install_cli_tool bat "enhanced cat with syntax highlighting"
install_cli_tool eza "modern ls replacement with Git integration"
install_cli_tool du-dust "intuitive disk usage analyzer"
install_cli_tool hyperfine "command-line benchmarking tool"
install_cli_tool bandwhich "network utilization by process"
