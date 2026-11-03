#!/usr/bin/env bash
# Install or remove native systemd resource limits for ordinary user sessions.
# Only user.slice and system.slice are configured. SSH authentication, daemon
# limits, OOM scores, and watchdogs are left to their existing configuration.
# Files are staged for reboot; no live limits or services are changed by apply.

set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit
# shellcheck source=header.sh
. header.sh

# --- Parameters ---

# Reserve whole physical cores, including all their online SMT siblings.
RESERVE_CORES=${RESERVE_CORES:-1}
# Start user reclaim at this percentage of physical RAM.
MEMORY_HIGH=${MEMORY_HIGH:-80}
# Cap aggregate user memory at this percentage of physical RAM.
MEMORY_MAX=${MEMORY_MAX:-90}
# Limit users to this percentage of the currently configured swap.
SWAP_PERCENT=${SWAP_PERCENT:-50}
# Limit aggregate user threads/processes to this percentage of system capacity.
TASKS_PERCENT=${TASKS_PERCENT:-50}
# Allow oomd to act when sustained user memory PSI exceeds this percentage.
PRESSURE=${PRESSURE:-40}
NAME=90-ssh-availability.conf
MARKER='# Managed by ConfigFiles SSH resilience.'
DESTINATION=
STATE=/var/lib/ssh-availability
stage=

usage() {
    cat <<'HELP'
Usage: ./install -s install_ssh_resilience -- [apply|dry-run|diagnose|uninstall|remove-obsolete]
apply stages two slice drop-ins for reboot; it does not change live limits.
uninstall removes this policy's files; reboot clears previously active limits.
rollback is an alias for uninstall. No command restarts SSH or reboots the host.
Parameters and limitations: docs/ssh-availability.md
HELP
}

# --- Native configuration ---

# Socket/core pairs keep repeated core IDs and SMT siblings in one partition.
workload_cpus() {
    awk -F, -v reserve="$RESERVE_CORES" '
        !/^#/ {
            if (NF != 3 || $1 !~ /^[0-9]+$/ || $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/) { bad=1; exit }
            key=$3 ":" $2
            if (!(key in cores)) cores[key]=++count
            if (cores[key] > reserve) { result=result separator $1; separator="," }
        }
        END { if (bad || result == "") exit 1; print result }'
}

render_policy() {
    local template=$1
    sed -e "s/@WORKLOAD_CPUS@/$WORKLOAD_CPUS/g" \
        -e "s/@MEMORY_HIGH@/$MEMORY_HIGH/g" -e "s/@MEMORY_MAX@/$MEMORY_MAX/g" \
        -e "s/@SWAP_MAX@/$SWAP_MAX/g" -e "s/@TASKS_PERCENT@/$TASKS_PERCENT/g" \
        -e "s/@PRESSURE@/$PRESSURE/g" "ssh_availability/$template.conf.in"
}

preflight() {
    [[ $(uname -s) == Linux && -d /run/systemd/system ]] || die 'A running Linux systemd host is required'
    [[ $(stat -fc %T /sys/fs/cgroup) == cgroup2fs ]] || die 'Unified cgroup v2 is required'
    [[ $(cat /sys/fs/cgroup/cpuset.cpus.effective) == "$(cat /sys/devices/system/cpu/online)" ]] || die 'Root CPU restrictions need review first'
    [[ $(systemctl --version | awk 'NR == 1 {print $2}') -ge 255 ]] || die 'systemd 255+ is required'
    [[ $(systemctl show systemd-oomd.service -p LoadState --value) == loaded ]] || die 'Install/unmask systemd-oomd first'
    local parameter value
    for parameter in cpu cpuset memory pids; do
        grep -qw "$parameter" /sys/fs/cgroup/cgroup.controllers || die "Missing cgroup controller: $parameter"
    done
    for parameter in RESERVE_CORES MEMORY_HIGH MEMORY_MAX SWAP_PERCENT TASKS_PERCENT PRESSURE; do
        value=${!parameter}
        [[ $value =~ ^(0|[1-9][0-9]*)$ && ${#value} -le 5 ]] || die "$parameter must be an integer"
    done
    (( RESERVE_CORES > 0 && MEMORY_HIGH > 0 && MEMORY_HIGH < MEMORY_MAX && MEMORY_MAX < 100 &&
       SWAP_PERCENT <= 100 && TASKS_PERCENT > 0 && TASKS_PERCENT <= 80 &&
       PRESSURE > 0 && PRESSURE <= 100 )) || die 'Parameters out of range'
    (( $(awk '/^MemTotal:/ {print $2}' /proc/meminfo) * (100 - MEMORY_MAX) / 100 >= 2097152 )) || die 'Leave at least 2 GiB outside user.slice; lower MEMORY_MAX'
    # Do not silently widen an administrator's existing CPU restrictions.
    systemctl cat user.slice --no-pager | awk '
        /^# \// { ours=($0 ~ /\/90-ssh-availability\.conf$/); next }
        !ours && /^[[:space:]]*(AllowedCPUs|StartupAllowedCPUs)[[:space:]]*=/ { bad=1 }
        END { exit bad }' || die 'Existing user.slice CPU policy needs review before installation'
}

# --- Owned files and legacy removal ---

# Preserve pending /etc edits before our changes, then record the result using
# etckeeper's existing metadata hooks and configured commit identity.
etc_checkpoint() {
    command_exists etckeeper || die 'etckeeper is required for configuration checkpoints'
    etckeeper commit -d "$DESTINATION/etc" "SSH resilience: $1" ||
        die 'Etckeeper checkpoint failed; inspect /etc before continuing'
}

owned_file() {
    local file=$1
    [[ -f $DESTINATION/$file && ! -L $DESTINATION/$file ]] || return 1
    grep -Fxq "$MARKER" "$DESTINATION/$file" || cmp -s "$DESTINATION/$file" "$STATE/installed/$file"
}

policy_paths() {
    printf '%s\n' "etc/systemd/system/user.slice.d/$NAME" "etc/systemd/system/system.slice.d/$NAME"
    # Earlier releases also changed SSH/oomd/watchdog settings. Only remove files
    # whose contents still match that release's saved installation copy.
    if [[ -f $STATE/manifest && ! -L $STATE ]]; then
        sed -n -E '\|^etc/systemd/system/[A-Za-z0-9_.-]+\.service\.d/90-ssh-availability\.conf$|p; \|^etc/ssh/sshd_config\.d/00-ssh-availability\.conf$|p; \|^etc/systemd/system\.conf\.d/90-ssh-availability\.conf$|p' "$STATE/manifest"
    fi
}

uninstall_policy() {
    local file
    [[ ! -L $STATE ]] || die 'Legacy state directory must not be a symlink'
    while IFS= read -r file; do
        [[ -e $DESTINATION/$file || -L $DESTINATION/$file ]] || continue
        owned_file "$file" || die "Modified or unmanaged /$file; review it with etckeeper before removal"
    done < <(policy_paths)
    etc_checkpoint 'before uninstall'
    while IFS= read -r file; do rm -f -- "$DESTINATION/$file"; done < <(policy_paths)
    etc_checkpoint 'after uninstall'
    info 'Policy files removed. No live limits or services changed. Reboot if the old policy was already active.'
}

remove_obsolete() {
    local unit=kill_vlc_on_resume.service
    if [[ -e /etc/systemd/system/$unit ]]; then
        systemctl disable --now "$unit"
        rm -f -- "/etc/systemd/system/$unit"
    fi
    systemctl daemon-reload
}

# --- CLI ---

main() {
    [[ $# -le 1 ]] || die 'Expected one action; use --help'
    case ${1:-apply} in
        --help|-h) usage; return ;;
        uninstall|rollback) is_root || die 'Run as root'; uninstall_policy; return ;;
        remove-obsolete) is_root || die 'Run as root'; remove_obsolete; return ;;
        diagnose)
            systemctl show user.slice system.slice -p EffectiveCPUs -p MemoryHigh -p MemoryMax -p MemorySwapMax -p TasksMax
            systemctl status systemd-oomd.service --no-pager
            return ;;
        apply|dry-run) ;;
        *) die 'Unknown action; use --help' ;;
    esac
    is_root || die 'Run as root'
    [[ ! -L $STATE ]] || die 'Legacy state directory must not be a symlink'
    preflight
    local file unit
    # Legacy SSH changes must be removed explicitly, not mixed into the new policy.
    if [[ -f $STATE/manifest ]]; then
        while IFS= read -r file; do
            [[ -e $DESTINATION/$file || -L $DESTINATION/$file ]] || continue
            case $file in
                etc/systemd/system/user.slice.d/*|etc/systemd/system/system.slice.d/*) ;;
                *) die 'Previous version detected. Run -- uninstall first; reboot if it was active, then install this version.' ;;
            esac
        done < <(policy_paths)
    fi
    WORKLOAD_CPUS=$(lscpu -b -p=CPU,CORE,SOCKET | workload_cpus) || die 'Not enough physical cores for this reservation'
    SWAP_MAX=$(( $(awk '/^SwapTotal:/ {print $2}' /proc/meminfo) * 1024 * SWAP_PERCENT / 100 ))
    stage=$(mktemp -d)
    trap '[[ -z $stage ]] || rm -r -- "$stage"' EXIT
    for unit in user.slice system.slice; do
        render_policy "$unit" > "$stage/$unit"
        printf '\n--- %s ---\n' "$unit"
        cat "$stage/$unit"
        file=etc/systemd/system/$unit.d/$NAME
        if [[ -e $DESTINATION/$file || -L $DESTINATION/$file ]]; then
            owned_file "$file" || die "Refusing to overwrite unmanaged /$file"
        fi
    done
    SYSTEMD_UNIT_PATH="$stage:" systemd-analyze verify --man=no --recursive-errors=no "$stage/user.slice" "$stage/system.slice"
    if [[ ${1:-apply} == apply ]]; then
        etc_checkpoint 'before install'
        for unit in user.slice system.slice; do
            install -D -m 644 "$stage/$unit" "$DESTINATION/etc/systemd/system/$unit.d/$NAME"
        done
        etc_checkpoint 'after install'
        info 'Two slice drop-ins installed for the next reboot. SSH configuration is unchanged; no services were restarted.'
    fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
