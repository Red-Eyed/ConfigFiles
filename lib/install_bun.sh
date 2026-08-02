#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

BUN_RELEASE_DELAY_DAYS=20
BUN_RELEASES_URL="https://api.github.com/repos/oven-sh/bun/releases?per_page=100"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

select_bun_release() {
    local releases_json
    releases_json=$(curl --proto '=https' --tlsv1.2 -fsSL "$BUN_RELEASES_URL")

    BUN_RELEASES_JSON="$releases_json" python3 - "$BUN_RELEASE_DELAY_DAYS" <<'PY'
import json
import os
import sys
from datetime import datetime, timedelta, timezone

delay_days = int(sys.argv[1])
cutoff = datetime.now(timezone.utc) - timedelta(days=delay_days)

for release in json.loads(os.environ["BUN_RELEASES_JSON"]):
    if release.get("draft") or release.get("prerelease"):
        continue

    tag = release.get("tag_name", "")
    if not tag.startswith("bun-v"):
        continue

    published_at = release.get("published_at")
    if published_at is None:
        continue

    published = datetime.fromisoformat(published_at.replace("Z", "+00:00"))
    if published <= cutoff:
        print(tag)
        raise SystemExit(0)

raise SystemExit(f"No stable Bun release older than {delay_days} days found")
PY
}

if ! command_exists bun; then
    bun_release=$(select_bun_release)
    info "Installing Bun ${bun_release}"
    curl --proto '=https' --tlsv1.2 -fsSL https://bun.com/install | bash -s "$bun_release"
else
    info "bun is already installed at $(command -v bun)"
fi
