#!/usr/bin/env bash
# Check CPU partitioning, configuration rendering, and removal of owned/legacy
# files. All filesystem changes stay in a temporary directory; no services run.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
# shellcheck source=lib/ssh_availability.sh
. "$repo/lib/ssh_availability.sh"
scratch=$(mktemp -d)
trap 'rm -r -- "$scratch"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# --- CPU topology ---

topology=$'0,0,0\n1,1,0\n2,0,1\n3,1,1\n8,0,0\n9,1,0\n10,0,1\n11,1,1'
[[ $(workload_cpus <<< "$topology") == 1,2,3,9,10,11 ]] || fail 'SMT or socket IDs mixed'
[[ $(RESERVE_CORES=2 workload_cpus <<< "$topology") == 2,3,10,11 ]] || fail 'Two-core reservation failed'
if RESERVE_CORES=4 workload_cpus <<< "$topology"; then fail 'All cores reserved'; fi
if workload_cpus <<< $'0,-,0\n1,1,0'; then fail 'Unknown topology accepted'; fi

# --- Rendered native configuration ---

WORKLOAD_CPUS=1-7,9-15
SWAP_MAX=1073741824
for unit in user.slice system.slice; do
    render_policy "$unit" > "$scratch/$unit"
    grep -Fxq "$MARKER" "$scratch/$unit"
    if grep -E '@[A-Z_]+@' "$scratch/$unit"; then fail 'Unexpanded parameter'; fi
    awk '/^[A-Za-z][A-Za-z0-9]*=/ && previous !~ /^#/ {exit 1} {previous=$0}' "$scratch/$unit"
done
grep -qx 'AllowedCPUs=' "$scratch/user.slice"
grep -qx 'AllowedCPUs=1-7,9-15' "$scratch/user.slice"
grep -qx 'TasksMax=50%' "$scratch/user.slice"

# --- Owned-file removal and legacy compatibility ---

DESTINATION=$scratch/root
STATE=$scratch/legacy
etckeeper() {
    [[ $1 == commit && $2 == -d && $3 == "$DESTINATION/etc" ]] || fail 'Incorrect etckeeper invocation'
    [[ ${checkpoint_fails:-no} != yes ]] || return 1
    printf '%s\n' "$4" >> "$scratch/checkpoints"
}
path=etc/systemd/system/user.slice.d/$NAME
legacy=etc/systemd/system/ssh.service.d/$NAME
mkdir -p "$DESTINATION/$(dirname "$path")" "$DESTINATION/$(dirname "$legacy")" "$STATE/installed/$(dirname "$legacy")"
cp "$scratch/user.slice" "$DESTINATION/$path"
printf '[Service]\nOOMScoreAdjust=-900\n' > "$DESTINATION/$legacy"
printf '%s\n' "$legacy" > "$STATE/manifest"
cp "$DESTINATION/$legacy" "$STATE/installed/$legacy"
printf '# manual edit\n' >> "$DESTINATION/$legacy"
if (uninstall_policy) 2>/dev/null; then fail 'Modified legacy file removed'; fi
[[ -e $DESTINATION/$path ]] || fail 'Failed removal partially deleted configuration'
cp "$STATE/installed/$legacy" "$DESTINATION/$legacy"
if (checkpoint_fails=yes uninstall_policy) 2>/dev/null; then fail 'Removal continued after checkpoint failure'; fi
[[ -e $DESTINATION/$path && -e $DESTINATION/$legacy ]] || fail 'Checkpoint failure changed files'
uninstall_policy
uninstall_policy
[[ ! -e $DESTINATION/$path && ! -e $DESTINATION/$legacy ]] || fail 'Owned files remain'
[[ -f $STATE/manifest ]] || fail 'Legacy reference state was deleted'
[[ $(cat "$scratch/checkpoints") == $'SSH resilience: before uninstall\nSSH resilience: after uninstall\nSSH resilience: before uninstall\nSSH resilience: after uninstall' ]] || fail 'Incorrect checkpoint order'

# --- Optional native parser check on a Linux test environment ---

if [[ ${NATIVE_VALIDATION:-0} == 1 ]]; then
    SYSTEMD_UNIT_PATH="$scratch:" systemd-analyze verify --man=no --recursive-errors=no "$scratch/user.slice" "$scratch/system.slice"
    printf '\nInvalidOption=yes\n' >> "$scratch/user.slice"
    if SYSTEMD_UNIT_PATH="$scratch:" systemd-analyze verify --man=no --recursive-errors=no "$scratch/user.slice" >/dev/null 2>&1; then
        fail 'Invalid unit accepted'
    fi
fi
printf 'PASS: topology, rendering, ownership, legacy removal, and requested native parser checks\n'
