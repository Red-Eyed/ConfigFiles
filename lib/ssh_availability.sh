#!/usr/bin/env bash
# Stage native systemd/OpenSSH resource protection on Linux servers, inspect the
# running configuration, or remove this utility's managed drop-ins.
# apply validates and writes files only; activation is deferred to an operator's
# reboot. remove-obsolete disables the legacy VLC unit and reloads systemd;
# no command restarts SSH, activates resource limits, or reboots the host.
# Deployment parameters and recovery limits: ../docs/ssh-availability.md.

set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit
# shellcheck source=header.sh
. header.sh

# --- Managed state and deployment parameters ---

STATE=/var/lib/ssh-availability
DESTINATION=
NAME=90-ssh-availability.conf
# Physical cores kept available to system services, including their SMT siblings.
RESERVE_CORES=${RESERVE_CORES:-1}
# Percent of physical RAM at which aggregate user reclaim begins.
MEMORY_HIGH=${MEMORY_HIGH:-80}
# Percent of physical RAM beyond which user allocations may trigger cgroup OOM.
MEMORY_MAX=${MEMORY_MAX:-90}
# Percent of configured swap available to all ordinary user sessions together.
SWAP_PERCENT=${SWAP_PERCENT:-50}
# Percent of the smallest host task limit available to the user slice.
TASKS_PERCENT=${TASKS_PERCENT:-50}
# Memory PSI threshold at which oomd considers killing user cgroups.
PRESSURE=${PRESSURE:-40}
# Authentication deadline in seconds; allow enough time for interactive MFA.
LOGIN_GRACE=${LOGIN_GRACE:-60}
# OpenSSH admission thresholds: start dropping, drop probability, reject all.
MAX_STARTUPS=${MAX_STARTUPS:-20:30:80}
# Watchdog timeout in seconds; zero omits the optional manager drop-in.
WATCHDOG_SEC=${WATCHDOG_SEC:-0}
# Optional service selection when discovery finds multiple distinct SSH daemons.
SSH_SERVICE=${SSH_SERVICE:-}
# Optional daemon path when sshd is outside PATH and the standard sbin/bin paths.
SSHD_BINARY=${SSHD_BINARY:-}
# Configuration read by this daemon; custom files need the standard drop-in Include.
SSHD_CONFIG=${SSHD_CONFIG:-/etc/ssh/sshd_config}
stage=

# --- Command help and parameter validation ---

usage() {
    cat <<'EOF'
Usage: sudo bash lib/ssh_availability.sh diagnose|dry-run|apply|rollback|remove-obsolete
       bash lib/ssh_availability.sh --help

apply only stages configuration for the next operator-scheduled reboot.
rollback removes staged configuration; reboot to undo already active policy.
Neither command reloads systemd, restarts SSH, kills processes, or reboots.
remove-obsolete disables/removes the legacy VLC unit and reloads systemd only.
Configuration is supplied through environment variables; see docs/ssh-availability.md.
EOF
}

integer() {
    [[ $2 =~ ^(0|[1-9][0-9]*)$ && ${#2} -le 7 ]] || die "$1 must be a canonical integer"
    (( 10#$2 >= $3 && 10#$2 <= $4 )) || die "$1 must be between $3 and $4"
}

validate_parameters() {
    integer RESERVE_CORES "$RESERVE_CORES" 1 65536
    integer MEMORY_HIGH "$MEMORY_HIGH" 1 98
    integer MEMORY_MAX "$MEMORY_MAX" 2 99
    integer SWAP_PERCENT "$SWAP_PERCENT" 0 90
    integer TASKS_PERCENT "$TASKS_PERCENT" 1 80
    integer PRESSURE "$PRESSURE" 1 100
    integer LOGIN_GRACE "$LOGIN_GRACE" 10 600
    integer WATCHDOG_SEC "$WATCHDOG_SEC" 0 600
    (( 10#$MEMORY_HIGH < 10#$MEMORY_MAX )) || die 'MEMORY_HIGH must be below MEMORY_MAX'
    [[ $MAX_STARTUPS =~ ^([0-9]+):([0-9]+):([0-9]+)$ ]] || die 'MAX_STARTUPS must be start:rate:full'
    local start=${BASH_REMATCH[1]} rate=${BASH_REMATCH[2]} full=${BASH_REMATCH[3]}
    integer start "$start" 1 4095
    integer rate "$rate" 1 100
    integer full "$full" 2 4096
    (( 10#$start < 10#$full )) || die 'MaxStartups full must exceed start'
    if [[ -n $SSH_SERVICE ]]; then
        [[ $SSH_SERVICE =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*\.service$ && $SSH_SERVICE != *..* ]] ||
            die 'SSH_SERVICE must name a non-template system service'
    fi
    [[ $SSHD_CONFIG == /etc/* && $SSHD_CONFIG =~ ^[A-Za-z0-9_./-]+$ && $SSHD_CONFIG != *..* ]] ||
        die 'SSHD_CONFIG must be a simple absolute path under /etc'
}

# --- SSH service discovery and PAM session placement ---

discover_ssh() {
    local candidate canonical selected='' path
    local candidates=(ssh.service sshd.service)
    if [[ -n $SSH_SERVICE ]]; then candidates=("$SSH_SERVICE"); fi
    for candidate in "${candidates[@]}"; do
        [[ $(systemctl show "$candidate" -p LoadState --value 2>/dev/null) == loaded ]] || continue
        canonical=$(systemctl show "$candidate" -p Id --value)
        [[ -z $selected || $selected == "$canonical" ]] ||
            die 'Multiple distinct SSH services found; set SSH_SERVICE explicitly'
        selected=$canonical
    done
    [[ -n $selected ]] || die 'No loaded SSH service found; install OpenSSH or set SSH_SERVICE'
    SSH_SERVICE=$selected
    if [[ -z $SSHD_BINARY ]]; then
        SSHD_BINARY=$(command -v sshd || true)
        for path in /usr/sbin/sshd /usr/bin/sshd /sbin/sshd; do
            [[ -z $SSHD_BINARY && -x $path ]] || continue
            SSHD_BINARY=$path
        done
    fi
    [[ -x $SSHD_BINARY ]] || die 'Cannot locate sshd; set SSHD_BINARY to its executable path'
    [[ -r $SSHD_CONFIG ]] || die "Cannot read $SSHD_CONFIG"
    info "SSH service: $SSH_SERVICE; daemon: $SSHD_BINARY; config: $SSHD_CONFIG"
}

# Follow session includes without executing PAM or treating auth-only rules as sessions.
pam_session_uses_systemd() {
    local directory=$1 service=$2 visited=${3:-:} file kind target
    [[ $service =~ ^[A-Za-z0-9_-]+$ && $visited != *":$service:"* ]] || return 1
    file=$directory/$service
    if [[ ! -r $file && $directory == /etc/pam.d ]]; then file=/usr/lib/pam.d/$service; fi
    [[ -r $file ]] || return 1
    while read -r kind target; do
        case $kind in
            module) [[ $target != pam_systemd.so && $target != */pam_systemd.so ]] || return 0 ;;
            include) if pam_session_uses_systemd "$directory" "$target" "$visited$service:"; then return 0; fi ;;
        esac
    done < <(awk '
        {
            sub(/#.*/, "")
            if (sub(/\\$/, "")) { pending = pending $0 " "; next }
            $0 = pending $0; pending = ""
            gsub(/\[[^]]*\]/, "control")
            if ($1 == "@include") print "include", $2
            else if ($1 == "session" || $1 == "-session") {
                if ($2 == "include" || $2 == "substack") print "include", $3
                else print "module", $3
            }
        }' "$file")
    return 1
}

check_ssh_socket_layout() {
    local socket
    for socket in ssh.socket sshd.socket; do
        [[ $(systemctl show "$socket" -p Accept --value 2>/dev/null) == yes ]] || continue
        if systemctl is-active --quiet "$socket" || systemctl is-enabled --quiet "$socket"; then
            die "$socket uses per-connection service instances; this activation layout is unsupported"
        fi
    done
}

# --- Host capabilities, CPU topology, and resource budgets ---

# Core IDs repeat across sockets. Keep all online SMT siblings in one partition.
partition_cpus() {
    awk -F, -v reserve="$1" '
        !/^#/ && NF == 3 {
            if ($1 !~ /^[0-9]+$/ || $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/) {
                invalid = 1
                exit 1
            }
            key = $3 ":" $2
            if (!(key in cores)) cores[key] = ++count
            if (cores[key] <= reserve) reserved = reserved sep1 $1
            else workload = workload sep2 $1
            if (cores[key] <= reserve) sep1 = ","; else sep2 = ","
        }
        END {
            if (invalid || count <= reserve || reserved == "" || workload == "") exit 1
            print reserved
            print workload
        }'
}

preflight() {
    [[ $(uname -s) == Linux ]] || die 'Linux is required'
    [[ $(stat -fc %T /sys/fs/cgroup) == cgroup2fs ]] || die 'Unified cgroup v2 is required'
    [[ $(cat /proc/1/comm) == systemd ]] || die 'systemd must be PID 1'
    local controller
    for controller in cpu cpuset memory pids io; do
        grep -qw "$controller" /sys/fs/cgroup/cgroup.controllers || die "Missing controller: $controller"
    done
    [[ -r /proc/pressure/memory ]] || die 'Kernel PSI support is required'
    systemctl --version
    [[ $(systemctl --version | awk 'NR == 1 {print $2}') -ge 255 ]] || die 'systemd 255+ is required'
    [[ $(systemctl show systemd-oomd.service -p LoadState --value) == loaded ]] ||
        die 'Install and unmask systemd-oomd before deployment'
    [[ $(systemctl show systemd-logind.service -p LoadState --value) == loaded ]] ||
        die 'systemd-logind must be available for PAM session placement'
    discover_ssh
    check_ssh_socket_layout
    "$SSHD_BINARY" -t -f "$SSHD_CONFIG"
    local settings pam_service
    settings=$("$SSHD_BINARY" -T -f "$SSHD_CONFIG")
    grep -qx 'usepam yes' <<< "$settings" || die 'UsePAM yes is required for session cgroup placement'
    pam_service=$(awk '$1 == "pamservicename" {print $2}' <<< "$settings")
    pam_session_uses_systemd /etc/pam.d "${pam_service:-sshd}" ||
        die 'Cannot find pam_systemd in the SSH session stack; review PAM configuration'
    if (( 10#$WATCHDOG_SEC > 0 )); then
        [[ -c /dev/watchdog0 && -r /sys/class/watchdog/watchdog0/identity ]] || die 'No watchdog0 device found'
        if systemctl is-active --quiet watchdog.service wd_keepalive.service; then
            die 'Another watchdog service is active; resolve device ownership first'
        fi
        warn 'Watchdog requested: verify hardware, ownership, and timeout support before reboot'
    fi
}

calculate_policy() {
    local partition mem_kib swap_kib pid_max threads_max root_pids task_base
    [[ $(cat /sys/fs/cgroup/cpuset.cpus.effective) == "$(cat /sys/devices/system/cpu/online)" ]] ||
        die 'Root cpuset differs from online CPUs; review host restrictions first'
    partition=$(lscpu -b -p=CPU,CORE,SOCKET | partition_cpus "$RESERVE_CORES") ||
        die 'Cannot reserve requested cores while leaving a workload core'
    SYSTEM_CPUS=${partition%%$'\n'*}
    WORKLOAD_CPUS=${partition#*$'\n'}
    mem_kib=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    swap_kib=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    (( mem_kib * (100 - 10#$MEMORY_MAX) / 100 >= 2097152 )) ||
        die 'Policy must leave at least 2 GiB RAM outside user.slice; lower MEMORY_MAX'
    SWAP_MAX=$(( swap_kib * 1024 * 10#$SWAP_PERCENT / 100 ))
    pid_max=$(cat /proc/sys/kernel/pid_max)
    threads_max=$(cat /proc/sys/kernel/threads-max)
    root_pids=$(cat /sys/fs/cgroup/pids.max 2>/dev/null || echo max)
    task_base=$pid_max
    (( threads_max >= task_base )) || task_base=$threads_max
    if [[ $root_pids != max ]]; then
        (( root_pids >= task_base )) || task_base=$root_pids
    fi
    TASKS_MAX=$(( task_base * 10#$TASKS_PERCENT / 100 ))
    info "Reserved CPUs: $SYSTEM_CPUS; user CPUs: $WORKLOAD_CPUS"
    info "User RAM high/max: $MEMORY_HIGH%/$MEMORY_MAX%; swap max: $SWAP_MAX bytes; tasks max: $TASKS_MAX"
    (( swap_kib > 0 )) || warn 'No swap: oomd has less time to react; no swap will be created'
}

# --- Candidate configuration and native parser validation ---

render() {
    local template=$1 target=$2
    mkdir -p "$(dirname "$stage/$target")"
    sed -e "s/@SYSTEM_CPUS@/$SYSTEM_CPUS/g" \
        -e "s/@WORKLOAD_CPUS@/$WORKLOAD_CPUS/g" \
        -e "s/@MEMORY_HIGH@/$MEMORY_HIGH/g" \
        -e "s/@MEMORY_MAX@/$MEMORY_MAX/g" \
        -e "s/@SWAP_MAX@/$SWAP_MAX/g" \
        -e "s/@TASKS_MAX@/$TASKS_MAX/g" \
        -e "s/@PRESSURE@/$PRESSURE/g" \
        -e "s/@LOGIN_GRACE@/$LOGIN_GRACE/g" \
        -e "s/@MAX_STARTUPS@/$MAX_STARTUPS/g" \
        -e "s/@WATCHDOG_SEC@/$WATCHDOG_SEC/g" "ssh_availability/$template.conf.in" > "$stage/$target"
    printf '%s\n' "$target" >> "$stage/manifest"
}

generate() {
    render user.slice "etc/systemd/system/user.slice.d/$NAME"
    render system.slice "etc/systemd/system/system.slice.d/$NAME"
    render ssh.service "etc/systemd/system/$SSH_SERVICE.d/$NAME"
    render oomd.service "etc/systemd/system/systemd-oomd.service.d/$NAME"
    render sshd "etc/ssh/sshd_config.d/00-ssh-availability.conf"
    if (( 10#$WATCHDOG_SEC > 0 )); then
        render watchdog "etc/systemd/system.conf.d/$NAME"
    fi
}

# Validate the candidate alongside existing unit drop-ins, without daemon-reload.
validate_units() {
    local root=$stage/validation unit dir file fragment existing
    mkdir -p "$root/etc/systemd/system"
    cp -a /etc/systemd/system/. "$root/etc/systemd/system/"
    while IFS= read -r file; do
        [[ $file == etc/systemd/system/* ]] || continue
        dir=$root/$(dirname "$file")
        # Never write through symlinks copied from the host into the dry-run tree.
        rm -rf -- "$dir"
        mkdir -p "$dir"
        for existing in "/$(dirname "$file")/"*.conf; do
            [[ -e $existing ]] || continue
            cp -L "$existing" "$dir/"
        done
        cp "$stage/$file" "$root/$file"
    done < "$stage/manifest"
    for unit in user.slice system.slice "$SSH_SERVICE" systemd-oomd.service; do
        dir=$root/etc/systemd/system
        # Copy the vendor fragment, replacing aliases that may point outside the tree.
        rm -f "$dir/$unit"
        fragment=$(systemctl show "$unit" -p FragmentPath --value)
        if [[ -n $fragment ]]; then
            cp -L "$fragment" "$dir/$unit"
        elif [[ $unit == system.slice ]]; then
            printf '[Slice]\n' > "$dir/$unit"
        else
            die "No unit fragment for $unit"
        fi
    done
    local unit_path
    unit_path=$(systemd-analyze unit-paths | paste -sd : -)
    unit_path=${unit_path//\/etc\/systemd\/system:/$root\/etc\/systemd\/system:}
    if ! SYSTEMD_UNIT_PATH="$unit_path" \
        systemd-analyze verify --man=no user.slice system.slice "$SSH_SERVICE" systemd-oomd.service \
        > "$stage/unit-validation.log" 2>&1; then
        cat "$stage/unit-validation.log" >&2
        die 'Unit validation failed'
    fi
    cat "$stage/unit-validation.log"
    if grep -Eqi 'Unknown|Invalid|Failed to parse|Failed to resolve' "$stage/unit-validation.log"; then
        die 'Resolve systemd validation warnings before applying'
    fi
}

validate_ssh() {
    local candidate=$stage/sshd_config settings file
    grep -Eqi '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config.d/\*\.conf[[:space:]]*$' "$SSHD_CONFIG" ||
        die 'Expected Include /etc/ssh/sshd_config.d/*.conf in SSHD_CONFIG; custom layout requires review'
    mkdir -p "$stage/ssh-includes"
    for file in /etc/ssh/sshd_config.d/*.conf; do
        [[ -e $file ]] || continue
        cp -L "$file" "$stage/ssh-includes/"
    done
    cp "$stage/etc/ssh/sshd_config.d/00-ssh-availability.conf" "$stage/ssh-includes/"
    sed "s|/etc/ssh/sshd_config.d/\*\.conf|$stage/ssh-includes/*.conf|g" "$SSHD_CONFIG" > "$candidate"
    "$SSHD_BINARY" -t -f "$candidate"
    settings=$("$SSHD_BINARY" -T -f "$candidate")
    grep -qx "logingracetime $((10#$LOGIN_GRACE))" <<< "$settings" || die 'LoginGraceTime validation failed'
    grep -qx "maxstartups $MAX_STARTUPS" <<< "$settings" || die 'MaxStartups validation failed'
}

show_plan() {
    local file
    while IFS= read -r file; do
        printf '\n--- /%s ---\n' "$file"
        cat "$stage/$file"
        if [[ -e $DESTINATION/$file ]]; then diff -u "$DESTINATION/$file" "$stage/$file" || true; fi
    done < "$stage/manifest"
    info 'Pending until reboot. No daemon reload, restart, process termination, or reboot will be performed.'
}

# --- Managed-file ownership, installation, and rollback ---

check_owned_files() {
    local file
    [[ ! -L $STATE ]] || die 'State directory must not be a symlink'
    [[ -f $STATE/manifest ]] || return 0
    while IFS= read -r file; do
        [[ $file == etc/* && $file != *..* ]] || die 'Invalid saved manifest'
        if [[ ! -e $DESTINATION/$file && ! -L $DESTINATION/$file ]]; then continue; fi
        [[ -f $DESTINATION/$file && ! -L $DESTINATION/$file ]] || die "Not a regular file: /$file"
        if ! cmp -s "$DESTINATION/$file" "$STATE/installed/$file" &&
            ! cmp -s "$DESTINATION/$file" "$STATE/previous/$file"; then
            die "Managed file was changed: /$file; reconcile it with $STATE before retrying"
        fi
    done < "$STATE/manifest"
}

install_policy() {
    local file
    check_owned_files
    if [[ -f $STATE/manifest ]]; then
        cmp -s "$STATE/manifest" "$stage/manifest" || die 'Rollback before changing the managed file set'
    fi
    while IFS= read -r file; do
        if [[ -e $DESTINATION/$file || -L $DESTINATION/$file ]]; then
            if [[ ! -f $STATE/manifest ]] || ! grep -Fxq "$file" "$STATE/manifest"; then
                die "Refusing to overwrite unmanaged /$file"
            fi
        fi
    done < "$stage/manifest"
    install -d -m 700 "$STATE"
    # Save ownership before writes, so interrupted installation is discoverable.
    atomic_install "$stage/manifest" "$STATE/manifest"
    while IFS= read -r file; do
        if [[ -f $DESTINATION/$file ]]; then
            atomic_install "$DESTINATION/$file" "$STATE/previous/$file"
        fi
        atomic_install "$stage/$file" "$STATE/installed/$file"
        atomic_install "$stage/$file" "$DESTINATION/$file"
    done < "$stage/manifest"
    info 'Configuration staged. Schedule a reboot with console/BMC access and then run diagnose.'
}

atomic_install() {
    local source=$1 target=$2 directory temporary
    directory=$(dirname "$target")
    mkdir -p "$directory"
    temporary=$(mktemp "$directory/.ssh-availability.XXXXXX")
    if ! install -m 644 "$source" "$temporary" || ! mv -f -- "$temporary" "$target"; then
        rm -f -- "$temporary"
        die "Cannot install $target"
    fi
}

rollback() {
    [[ -f $STATE/manifest ]] || { info 'Nothing installed'; return; }
    check_owned_files
    local file
    while IFS= read -r file; do
        rm -f -- "$DESTINATION/$file"
    done < "$STATE/manifest"
    rm -r -- "$STATE"
    info 'Owned drop-ins removed. Reboot to remove policy already loaded by systemd/sshd.'
}

# --- Explicit migration from obsolete repository services ---

remove_obsolete() {
    local unit=kill_vlc_on_resume.service
    local file=/etc/systemd/system/$unit
    [[ $(uname -s) == Linux && -d /run/systemd/system ]] || die 'A running Linux systemd host is required'
    if [[ -e $file || -L $file ]]; then
        systemctl disable --now "$unit"
        rm -f -- "$file"
    fi
    systemctl daemon-reload
    info 'Obsolete VLC unit removed; SSH and resource limits were not restarted or changed.'
}

# --- Read-only runtime diagnostics ---

report() {
    printf '\n--- %s ---\n' "$*"
    "$@" || warn 'Diagnostic unavailable or failed (permissions, missing tool, or inactive unit)'
}

diagnose() {
    if (discover_ssh) >/dev/null 2>&1; then
        discover_ssh
    else
        warn 'SSH discovery failed; set SSH_SERVICE/SSHD_BINARY/SSHD_CONFIG for this layout'
        SSH_SERVICE=${SSH_SERVICE:-ssh.service}
        SSHD_BINARY=${SSHD_BINARY:-sshd}
    fi
    report uname -a
    report cat /etc/os-release
    report lscpu -e=CPU,CORE,SOCKET,NODE,ONLINE
    report free -h
    report swapon --show
    report systemctl --version
    report findmnt -t cgroup2
    report cat /sys/fs/cgroup/cgroup.controllers
    local unit path property pid file
    local sockets
    sockets=$(systemctl show "$SSH_SERVICE" -p TriggeredBy --value 2>/dev/null || true)
    local units=(user.slice system.slice "$SSH_SERVICE" systemd-oomd.service)
    for unit in $sockets; do
        [[ $unit != *.socket ]] || units+=("$unit")
    done
    for unit in "${units[@]}"; do
        report systemctl status --no-pager "$unit"
        report systemctl cat "$unit"
        report systemctl show "$unit" -p ControlGroup -p ActiveState -p UnitFileState \
            -p AllowedCPUs -p EffectiveCPUs -p CPUWeight -p MemoryCurrent -p MemoryHigh \
            -p MemoryMax -p MemorySwapMax -p TasksCurrent -p TasksMax -p IOWeight \
            -p OOMScoreAdjust -p LimitNOFILE -p LimitNPROC -p LimitMEMLOCK -p MemoryLow \
            -p ManagedOOMMemoryPressure -p ManagedOOMMemoryPressureLimit -p ManagedOOMSwap
        path=$(systemctl show "$unit" -p ControlGroup --value 2>/dev/null || true)
        [[ $path == /* && $path != / ]] || continue
        for property in cpuset.cpus.effective memory.current memory.high memory.max memory.swap.max \
            memory.events pids.current pids.max pids.events cpu.pressure memory.pressure io.pressure; do
            file=/sys/fs/cgroup$path/$property
            [[ ! -r $file ]] || report cat "$file"
        done
    done
    report "$SSHD_BINARY" -T -f "$SSHD_CONFIG"
    report ss -lntp
    report oomctl
    report systemd-analyze cat-config systemd/oomd.conf
    report systemd-analyze cat-config systemd/system.conf
    report systemctl show -p RuntimeWatchdogUSec -p WatchdogDevice
    for file in /sys/class/watchdog/watchdog*/identity /sys/class/watchdog/watchdog*/timeout \
        /proc/pressure/* /proc/sys/fs/file-nr /proc/sys/fs/file-max \
        /proc/sys/kernel/pid_max /proc/sys/kernel/threads-max; do
        [[ ! -r $file ]] || report cat "$file"
    done
    report journalctl -k -b --no-pager --grep='oom|Out of memory|Killed process'
    report journalctl -b -u systemd-oomd --no-pager -n 50
    report loginctl list-sessions
    report ps -eo uid,pid,ppid,ni,cls,cgroup:100,args --sort=uid
    pid=$(systemctl show "$SSH_SERVICE" -p MainPID --value 2>/dev/null || true)
    if [[ $pid =~ ^[1-9][0-9]*$ ]]; then report cat "/proc/$pid/oom_score_adj" "/proc/$pid/limits"; fi
    report cat /proc/self/cgroup /proc/self/limits /proc/self/oom_score_adj
    report df -h / /var /home
    report df -i / /var /home
    report lsblk -o NAME,TYPE,SIZE,MOUNTPOINTS,SCHED
    info 'Inspect ordinary user processes under /user.slice. A successful fresh remote login remains the availability test.'
    [[ ! -f $STATE/manifest ]] || report cat "$STATE/manifest"
}

# --- Command dispatch ---

main() {
    [[ $# -le 1 ]] || { usage; exit 2; }
    case ${1:---help} in
        --help|-h) usage; return ;;
        diagnose) diagnose; return ;;
        rollback) is_root || die 'Run as root'; rollback; return ;;
        remove-obsolete) is_root || die 'Run as root'; remove_obsolete; return ;;
        dry-run|apply) ;;
        *) usage; exit 2 ;;
    esac
    is_root || die 'Run as root to validate existing SSH and systemd configuration'
    validate_parameters
    preflight
    calculate_policy
    stage=$(mktemp -d)
    trap '[[ -z $stage ]] || rm -r -- "$stage"' EXIT
    generate
    validate_units
    validate_ssh
    show_plan
    [[ $1 != apply ]] || install_policy
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
