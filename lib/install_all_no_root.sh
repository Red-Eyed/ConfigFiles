#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

installed=()
failed=()

run_installer() {
    local name="$1" script="$2"

    info "Starting $name"
    if "$script"; then
        installed+=("$name")
    else
        warn "$name installation failed; continuing"
        failed+=("$name")
    fi
}

print_report() {
    echo
    info "Install report"

    if ((${#installed[@]} > 0)); then
        info "Installed or already present:"
        printf '  - %s\n' "${installed[@]}"
    fi

    if ((${#failed[@]} > 0)); then
        warn "Not installed:"
        printf '  - %s\n' "${failed[@]}" >&2
    fi
}

run_installer "dotfiles" ./install_dotfiles.sh
run_installer "uv" ./install_uv.sh
run_installer "go" ./install_golang.sh
run_installer "node" ./install_node.sh
run_installer "bun" ./install_bun.sh
run_installer "cargo" ./install_cargo.sh
run_installer "cargo packages" ./install_cargo_packages.sh

print_report
exit 0
