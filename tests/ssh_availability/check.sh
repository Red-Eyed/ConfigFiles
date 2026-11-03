#!/usr/bin/env bash
# Verify SSH availability policy, distribution discovery, and managed-file safety.
# Pure checks run on macOS and Linux; Linux file lifecycle checks use temporary
# destinations. NATIVE_VALIDATION=1 also reads the host's installed configuration
# through systemd/sshd parsers, without starting services or running stress tests.

set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
# shellcheck source=lib/ssh_availability.sh
. "$repo/lib/ssh_availability.sh"

scratch=$(mktemp -d)
trap 'rm -r -- "$scratch"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# --- CPU topology and SMT partitioning ---

topology='# CPU,Core,Socket
0,0,0
1,1,0
2,0,1
3,1,1
8,0,0
9,1,0
10,0,1
11,1,1'
actual=$(partition_cpus 1 <<< "$topology")
[[ $actual == $'0,8\n1,2,3,9,10,11' ]] || fail 'SMT siblings or socket IDs were mixed'
actual=$(partition_cpus 2 <<< "$topology")
[[ $actual == $'0,1,8,9\n2,3,10,11' ]] || fail 'Two-core reservation failed'
if partition_cpus 4 <<< "$topology"; then fail 'All-core reservation was accepted'; fi
if partition_cpus 1 <<< '0,0,0'; then fail 'Single-core host was accepted'; fi
if partition_cpus 1 <<< $'0,-,0\n1,1,0'; then fail 'Unknown topology accepted'; fi
[[ $(partition_cpus 1 <<< $'2,4,0\n7,9,0') == $'2\n7' ]] || fail 'Sparse CPU IDs failed'

# --- Invalid deployment parameters ---

validate_parameters
if (MEMORY_HIGH=95 MEMORY_MAX=90 validate_parameters) 2>/dev/null; then fail 'Inverted limits accepted'; fi
if (RESERVE_CORES=0 validate_parameters) 2>/dev/null; then fail 'Zero reservation accepted'; fi
if (LOGIN_GRACE=010 validate_parameters) 2>/dev/null; then fail 'Ambiguous numeric accepted'; fi
if (MAX_STARTUPS=80:30:20 validate_parameters) 2>/dev/null; then fail 'Inverted MaxStartups accepted'; fi
if (MAX_STARTUPS='20:30:80;false' validate_parameters) 2>/dev/null; then fail 'Invalid text accepted'; fi
if (SSH_SERVICE='../sshd.service' validate_parameters) 2>/dev/null; then fail 'Invalid service path accepted'; fi

# --- PAM session include traversal ---

mkdir "$scratch/pam"
printf '@include common-session\n' > "$scratch/pam/sshd"
printf 'session optional pam_systemd.so\n' > "$scratch/pam/common-session"
pam_session_uses_systemd "$scratch/pam" sshd || fail 'Debian PAM include not followed'
printf 'session substack password-auth\n' > "$scratch/pam/sshd"
printf 'session include system-auth\n' > "$scratch/pam/password-auth"
printf -- '-session [success=ok default=ignore] /usr/lib/security/pam_systemd.so\n' > "$scratch/pam/system-auth"
pam_session_uses_systemd "$scratch/pam" sshd || fail 'Fedora PAM session includes not followed'
printf 'auth include system-auth\n# session optional pam_systemd.so\n' > "$scratch/pam/sshd"
if pam_session_uses_systemd "$scratch/pam" sshd; then fail 'Auth-only or commented PAM rule accepted'; fi
printf 'session include sshd\n' > "$scratch/pam/sshd"
if pam_session_uses_systemd "$scratch/pam" sshd; then fail 'Cyclic PAM stack accepted'; fi
printf 'session optional pam_exec.so pam_systemd.so\n' > "$scratch/pam/sshd"
if pam_session_uses_systemd "$scratch/pam" sshd; then fail 'PAM module argument mistaken for module'; fi

# --- Distribution-specific service names and aliases ---

check_discovery() (
    local layout=$1 expected=$2
    SSH_SERVICE=
    SSHD_BINARY=/usr/bin/true
    SSHD_CONFIG=$scratch/pam/sshd
    systemctl() {
        case "$layout:$2:$4" in
            ubuntu:ssh.service:LoadState|ubuntu:sshd.service:LoadState|fedora:sshd.service:LoadState|dual:*:LoadState) echo loaded ;;
            ubuntu:*:Id) echo ssh.service ;;
            fedora:*:Id) echo sshd.service ;;
            dual:*:Id) echo "$2" ;;
            *) echo not-found ;;
        esac
    }
    discover_ssh
    [[ $SSH_SERVICE == "$expected" ]] || fail 'Wrong canonical SSH service selected'
)
check_discovery ubuntu ssh.service
check_discovery fedora sshd.service
if (check_discovery dual ssh.service) 2>/dev/null; then fail 'Ambiguous SSH services accepted'; fi

# --- Unsupported per-connection socket activation ---

check_socket_layout() (
    local accept=$1
    systemctl() {
        case $1 in
            show) echo "$accept" ;;
            is-active) return 0 ;;
        esac
    }
    check_ssh_socket_layout
)
check_socket_layout no
if (check_socket_layout yes) 2>/dev/null; then fail 'Per-connection socket activation accepted'; fi

# --- Option documentation and rendered configuration ---

for template in "$repo"/lib/ssh_availability/*.conf.in; do
    awk '
        /^[A-Za-z][A-Za-z0-9]*[= ]/ && previous !~ /^#/ { exit 1 }
        { previous = $0 }
    ' "$template" || fail "Configuration option lacks adjacent comment: $template"
done

stage=$scratch/stage
mkdir "$stage"
SYSTEM_CPUS=0,8
WORKLOAD_CPUS=1-7,9-15
SWAP_MAX=1073741824
TASKS_MAX=8192
SSH_SERVICE=ssh.service
if [[ ${NATIVE_VALIDATION:-0} == 1 && -f /usr/lib/systemd/system/sshd.service ]]; then SSH_SERVICE=sshd.service; fi
SSHD_BINARY=$(command -v sshd || echo /usr/sbin/sshd)
generate
[[ $(wc -l < "$stage/manifest") -eq 5 ]] || fail 'Unexpected default file set'
if grep -RE '@[A-Z_]+@' "$stage/etc"; then fail 'Unexpanded placeholders'; fi
grep -qx 'AllowedCPUs=0,8' "$stage/etc/systemd/system/$SSH_SERVICE.d/$NAME"
grep -qx 'MemoryMax=90%' "$stage/etc/systemd/system/user.slice.d/$NAME"
grep -qx 'ManagedOOMMemoryPressure=kill' "$stage/etc/systemd/system/user.slice.d/$NAME"

if [[ $(uname -s) != Linux ]]; then
    printf 'PASS: policy and rendering; Linux file/native parser checks skipped\n'
    exit 0
fi

# --- Isolated installation, ownership, and rollback ---

DESTINATION=$scratch/destination
STATE=$scratch/state
mkdir -p "$DESTINATION/etc/ssh/sshd_config.d"
printf 'unmanaged\n' > "$DESTINATION/etc/ssh/sshd_config.d/00-ssh-availability.conf"
if (install_policy) 2>/dev/null; then fail 'Unmanaged configuration overwritten'; fi
[[ ! -e $STATE ]] || fail 'Refused install changed state'
rm "$DESTINATION/etc/ssh/sshd_config.d/00-ssh-availability.conf"
install_policy
[[ $(stat -c %a "$STATE") == 700 ]] || fail 'State directory permissions changed'
install_policy
printf '# edited\n' >> "$DESTINATION/etc/ssh/sshd_config.d/00-ssh-availability.conf"
if (rollback) 2>/dev/null; then fail 'Edited file removed'; fi
cp "$STATE/installed/etc/ssh/sshd_config.d/00-ssh-availability.conf" "$DESTINATION/etc/ssh/sshd_config.d/00-ssh-availability.conf"
rollback
rollback
[[ ! -e $STATE ]] || fail 'Rollback left state'
while IFS= read -r file; do
    [[ ! -e $DESTINATION/$file ]] || fail 'Rollback left configuration'
done < "$stage/manifest"

# --- Interrupted deployment and managed-file set changes ---

# Simulate interruption after the manifest and some files were written.
install_policy
rm "$DESTINATION/etc/ssh/sshd_config.d/00-ssh-availability.conf"
install_policy
printf '# replacement\n' >> "$stage/etc/ssh/sshd_config.d/00-ssh-availability.conf"
install_policy
cp "$STATE/previous/etc/ssh/sshd_config.d/00-ssh-availability.conf" "$DESTINATION/etc/ssh/sshd_config.d/00-ssh-availability.conf"
check_owned_files
rollback

# A changed file set must fail before touching any destination.
install_policy
WATCHDOG_SEC=60
render watchdog "etc/systemd/system.conf.d/$NAME"
if (install_policy) 2>/dev/null; then fail 'Managed file set changed in place'; fi
rollback

# --- Optional native parser acceptance and rejection ---

if [[ ${NATIVE_VALIDATION:-0} == 1 ]]; then
    # An offline container has no system manager; only fragment lookup is stubbed.
    systemctl() {
        if [[ -f /usr/lib/systemd/system/$2 ]]; then
            printf '/usr/lib/systemd/system/%s\n' "$2"
        fi
    }
    validate_units
    validate_ssh
    printf '\nNotARealSystemdOption=1\n' >> "$stage/etc/systemd/system/$SSH_SERVICE.d/$NAME"
    if (validate_units) >/dev/null 2>&1; then fail 'Unknown unit option accepted'; fi
    printf 'InvalidSSHOption yes\n' >> "$stage/etc/ssh/sshd_config.d/00-ssh-availability.conf"
    if (validate_ssh) >/dev/null 2>&1; then fail 'Invalid sshd option accepted'; fi
fi
printf 'PASS: policy, rendering, ownership, idempotency, rollback, interruption, and requested native parser checks\n'
