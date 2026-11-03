#!/usr/bin/env bash
# Explicit installer entry for SSH availability protection; omitted from install_all.
# Forward only documented policy parameters through sudo. The underlying utility
# stages files for reboot and never restarts SSH or activates live resource limits.

set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit
# shellcheck source=header.sh
. header.sh

# --- Action selection ---

action=${1:-apply}
[[ $# -le 1 ]] || die 'Usage: ./install -s install_ssh_resilience -- [apply|dry-run|diagnose|rollback]'
case $action in
    apply|dry-run|diagnose|rollback|--help|-h) ;;
    *) die "Unknown SSH resilience action: $action" ;;
esac
command=(bash "$PWD/ssh_availability.sh" "$action")
if [[ $action == --help || $action == -h ]] || is_root; then
    exec "${command[@]}"
fi

# --- Privilege elevation with explicit configuration forwarding ---

parameters=(
    RESERVE_CORES MEMORY_HIGH MEMORY_MAX SWAP_PERCENT TASKS_PERCENT PRESSURE
    LOGIN_GRACE MAX_STARTUPS WATCHDOG_SEC SSH_SERVICE SSHD_BINARY SSHD_CONFIG
)
settings=()
for parameter in "${parameters[@]}"; do
    if value=$(printenv "$parameter"); then
        settings+=("$parameter=$value")
    fi
done
exec sudo env "${settings[@]}" "${command[@]}"
