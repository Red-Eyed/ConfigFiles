#!/usr/bin/env bash
set -eo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

BUN_RELEASE_DELAY_DAYS=20
BUN_RELEASE_DATE_FORMAT="+%Y-%m-%dT%H:%M:%SZ"
BUN_RELEASES_URL="https://api.github.com/repos/oven-sh/bun/releases?per_page=100"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

release_cutoff() {
    if date -u \
        -d "${BUN_RELEASE_DELAY_DAYS} days ago" \
        "$BUN_RELEASE_DATE_FORMAT" >/dev/null 2>&1; then
        date -u -d "${BUN_RELEASE_DELAY_DAYS} days ago" "$BUN_RELEASE_DATE_FORMAT"
    else
        date -u -v-"${BUN_RELEASE_DELAY_DAYS}"d "$BUN_RELEASE_DATE_FORMAT"
    fi
}

select_bun_release() {
    local cutoff draft prerelease published_at releases_json tag
    cutoff=$(release_cutoff)
    releases_json=$(curl --proto '=https' --tlsv1.2 -fsSL "$BUN_RELEASES_URL")

    while read -r field value; do
        case "$field" in
            tag_name)
                tag="$value"
                ;;
            draft)
                draft="$value"
                ;;
            prerelease)
                prerelease="$value"
                ;;
            published_at)
                published_at="$value"
                if [[ "$tag" == bun-v* ]] &&
                    [[ "$draft" == false ]] &&
                    [[ "$prerelease" == false ]]; then
                    if [[ "$published_at" < "$cutoff" ]] ||
                        [[ "$published_at" == "$cutoff" ]]; then
                        printf '%s\n' "$tag"
                        return 0
                    fi
                fi
                ;;
        esac
    done < <(parse_bun_releases "$releases_json")

    error "No stable Bun release older than ${BUN_RELEASE_DELAY_DAYS} days found"
    return 1
}

parse_bun_releases() {
    sed -nE '
        s/^[[:space:]]*"tag_name": "([^"]+)".*/tag_name \1/p
        s/^[[:space:]]*"draft": (true|false).*/draft \1/p
        s/^[[:space:]]*"prerelease": (true|false).*/prerelease \1/p
        s/^[[:space:]]*"published_at": "([^"]+)".*/published_at \1/p
    ' <<<"$1"
}

if ! command_exists bun; then
    bun_release=$(select_bun_release)
    info "Installing Bun ${bun_release}"
    curl --proto '=https' --tlsv1.2 -fsSL https://bun.com/install |
        bash -s "$bun_release"
    command_exists bun || die "Bun installation completed but bun is not in PATH"
else
    info "bun is already installed at $(command -v bun)"
fi
