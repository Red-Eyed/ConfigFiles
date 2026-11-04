#!/usr/bin/env bash
# Check earlyoom arguments and safe removal of the old installer's files.
# Uses temporary files only; native parser validation is explicitly optional.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
# shellcheck source=lib/install_earlyoom.sh
. "$repo/lib/install_earlyoom.sh"
scratch=$(mktemp -d)
trap 'rm -r -- "$scratch"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# --- One native service drop-in ---

EARLYOOM_BINARY=$(command -v earlyoom || echo /usr/bin/earlyoom)
render_config > "$scratch/policy.conf"
grep -Fxq "$MARKER" "$scratch/policy.conf"
grep -q -- '-m 20,15 -s 100,100 -g -r 3600' "$scratch/policy.conf"
if grep -E '@[A-Z_]+@' "$scratch/policy.conf"; then fail 'Unexpanded options'; fi
awk '/^ExecStart=/ && previous !~ /^#/ {exit 1} {previous=$0}' "$scratch/policy.conf"

# --- Legacy migration preserves unrelated and manually changed files ---

DESTINATION=$scratch/root
LEGACY_STATE=$scratch/legacy
old=etc/systemd/system/user.slice.d/90-ssh-availability.conf
original=etc/ssh/sshd_config.d/00-ssh-availability.conf
mkdir -p "$DESTINATION/$(dirname "$old")" "$DESTINATION/$(dirname "$original")" "$LEGACY_STATE/installed/$(dirname "$original")"
printf '# Managed by ConfigFiles SSH resilience.\n[Slice]\nMemoryMax=90%%\n' > "$DESTINATION/$old"
printf 'LoginGraceTime 60\n' > "$DESTINATION/$original"
printf '%s\n' "$original" > "$LEGACY_STATE/manifest"
cp "$DESTINATION/$original" "$LEGACY_STATE/installed/$original"
printf 'changed\n' >> "$DESTINATION/$original"
if (check_owned_files) 2>/dev/null; then fail 'Changed legacy file accepted'; fi
[[ -f $DESTINATION/$old ]] || fail 'Check changed configuration'
cp "$LEGACY_STATE/installed/$original" "$DESTINATION/$original"
printf 'untouched\n' > "$DESTINATION/etc/unrelated"
check_owned_files
remove_legacy
remove_legacy
[[ ! -e $DESTINATION/$old && ! -e $DESTINATION/$original ]] || fail 'Legacy files remain'
[[ $(cat "$DESTINATION/etc/unrelated") == untouched ]] || fail 'Unrelated file changed'
[[ -f $LEGACY_STATE/manifest ]] || fail 'Legacy reference state deleted'

# --- Real distribution unit parser ---

if [[ ${NATIVE_VALIDATION:-0} == 1 ]]; then
    mkdir "$scratch/earlyoom.service.d"
    cp /usr/lib/systemd/system/earlyoom.service "$scratch/earlyoom.service"
    cp "$scratch/policy.conf" "$scratch/earlyoom.service.d/90-configfiles-earlyoom.conf"
    SYSTEMD_UNIT_PATH="$scratch:" systemd-analyze verify --man=no --recursive-errors=no "$scratch/earlyoom.service"
fi
printf 'PASS: earlyoom configuration and legacy migration\n'
