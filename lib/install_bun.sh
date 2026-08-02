#!/usr/bin/env bash
set -eo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

BUN_RELEASE_DELAY_DAYS=20
BUN_REPO_URL="https://github.com/oven-sh/bun.git"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

select_bun_release() (
    local commit repo_dir tag
    repo_dir=$(mktemp -d "${TMPDIR:-/tmp}/bun-release.XXXXXX")
    trap 'rm -rf "$repo_dir"' EXIT

    git -C "$repo_dir" init --quiet
    git -C "$repo_dir" remote add origin "$BUN_REPO_URL"
    git -C "$repo_dir" fetch --quiet --depth=1 origin \
        "refs/tags/bun-v*:refs/tags/bun-v*"

    while read -r tag; do
        commit=$(git -C "$repo_dir" log -1 \
            --before="${BUN_RELEASE_DELAY_DAYS} days ago" \
            --format="%H" \
            "$tag")

        if [[ -n "$commit" ]]; then
            printf '%s\n' "$tag"
            return 0
        fi
    done < <(
        git -C "$repo_dir" for-each-ref \
            --sort=-creatordate \
            --format='%(refname:short)' \
            refs/tags/bun-v
    )

    error "No stable Bun release older than ${BUN_RELEASE_DELAY_DAYS} days found"
    return 1
)

if ! command_exists bun; then
    bun_release=$(select_bun_release)
    info "Installing Bun ${bun_release}"
    curl --proto '=https' --tlsv1.2 -fsSL https://bun.com/install | bash -s "$bun_release"
    command_exists bun || die "Bun installation completed but bun is not in PATH"
else
    info "bun is already installed at $(command -v bun)"
fi
