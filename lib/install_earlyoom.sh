#!/usr/bin/env bash
# Configure the packaged earlyoom service for Python multiprocessing workloads.
# Legacy ConfigFiles slice limits are removed; this installer does not create
# its own cgroup policy or restart SSH.

set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit
# shellcheck source=header.sh
. header.sh

# --- Options ---

# Available-memory percentage at which the selected process group gets SIGTERM.
EARLYOOM_TERM=${EARLYOOM_TERM:-20}
# Lower available-memory percentage at which the group gets SIGKILL.
EARLYOOM_KILL=${EARLYOOM_KILL:-15}
DROPIN=etc/systemd/system/earlyoom.service.d/90-configfiles-earlyoom.conf
MARKER='# Managed by ConfigFiles earlyoom.'
DESTINATION=
LEGACY_STATE=/var/lib/ssh-availability
stage=

usage() {
    cat <<'HELP'
Usage: ./install -s install_earlyoom -- [apply|dry-run|diagnose|uninstall]
apply installs earlyoom if missing, configures it, and starts it immediately.
uninstall removes our configuration and reloads the package defaults.
EARLYOOM_TERM=20 EARLYOOM_KILL=15 control available-memory thresholds.
No custom slice limits, SSH restart, or automatic reboot. See docs/earlyoom.md.
HELP
}

# --- Configuration ---

render_config() {
    sed -e "s|@EARLYOOM_BINARY@|$EARLYOOM_BINARY|g" \
        -e "s/@EARLYOOM_TERM@/$EARLYOOM_TERM/g" \
        -e "s/@EARLYOOM_KILL@/$EARLYOOM_KILL/g" earlyoom/service.conf.in
}

owned_file() {
    local file=$1
    [[ -f $DESTINATION/$file && ! -L $DESTINATION/$file ]] || return 1
    grep -Fxq "$MARKER" "$DESTINATION/$file" ||
        grep -Fxq '# Managed by ConfigFiles SSH resilience.' "$DESTINATION/$file" ||
        cmp -s "$DESTINATION/$file" "$LEGACY_STATE/installed/$file"
}

# --- One-time cleanup of the earlier installer ---

legacy_paths() {
    printf '%s\n' etc/systemd/system/user.slice.d/90-ssh-availability.conf \
        etc/systemd/system/system.slice.d/90-ssh-availability.conf \
        etc/systemd/system/earlyoom.service.d/90-ssh-availability.conf
    if [[ -f $LEGACY_STATE/manifest ]]; then
        sed -n -E '\|^etc/systemd/system/[A-Za-z0-9_.-]+\.service\.d/90-ssh-availability\.conf$|p; \|^etc/ssh/sshd_config\.d/00-ssh-availability\.conf$|p; \|^etc/systemd/system\.conf\.d/90-ssh-availability\.conf$|p' "$LEGACY_STATE/manifest"
    fi
}

check_owned_files() {
    local file
    [[ ! -L $LEGACY_STATE ]] || die 'Legacy state must not be a symlink'
    while IFS= read -r file; do
        [[ -e $DESTINATION/$file || -L $DESTINATION/$file ]] || continue
        owned_file "$file" || die "Modified or unmanaged /$file; review it before removal"
    done < <(printf '%s\n' "$DROPIN"; legacy_paths)
}

remove_legacy() {
    local file
    while IFS= read -r file; do
        [[ -e $DESTINATION/$file ]] || continue
        rm -f -- "$DESTINATION/$file"
        case $file in
            etc/ssh/*|etc/systemd/system.conf.d/*|etc/systemd/system/ssh*.service.d/*)
                warn 'Original SSH/watchdog overrides removed; already-running processes may need a one-time restart/reboot.' ;;
        esac
    done < <(legacy_paths)
}

# --- CLI ---

main() {
    local action=${1:-apply} arguments unit
    [[ $# -le 1 ]] || die 'Expected one action; use --help'
    case $action in
        --help|-h) usage; return ;;
        apply|dry-run|diagnose|uninstall|rollback|remove-obsolete) ;;
        *) die 'Unknown action; use --help' ;;
    esac
    if ! is_root; then
        exec sudo env EARLYOOM_TERM="$EARLYOOM_TERM" EARLYOOM_KILL="$EARLYOOM_KILL" bash "$PWD/install_earlyoom.sh" "$action"
    fi
    [[ $(uname -s) == Linux && -d /run/systemd/system ]] || die 'A running Linux systemd host is required'
    case $action in
        diagnose) systemctl status earlyoom.service --no-pager; journalctl -u earlyoom.service --no-pager -n 20; return ;;
        remove-obsolete)
            if [[ -e /etc/systemd/system/kill_vlc_on_resume.service ]]; then
                systemctl disable --now kill_vlc_on_resume.service
                rm -f /etc/systemd/system/kill_vlc_on_resume.service
            fi
            systemctl daemon-reload
            return ;;
    esac
    check_owned_files
    if [[ $action == uninstall || $action == rollback ]]; then
        remove_legacy
        rm -f -- "$DESTINATION/$DROPIN"
        systemctl unmask systemd-oomd.service systemd-oomd.socket
        systemctl daemon-reload
        if systemctl is-active --quiet earlyoom.service; then systemctl restart earlyoom.service; fi
        info 'Our configuration removed. Earlyoom remains installed with package defaults; systemd-oomd is unmasked.'
        return
    fi
    [[ $EARLYOOM_TERM =~ ^[1-9][0-9]?$ && $EARLYOOM_KILL =~ ^[1-9][0-9]?$ ]] || die 'Memory thresholds must be integers from 1 to 99'
    (( EARLYOOM_KILL <= EARLYOOM_TERM )) || die 'EARLYOOM_KILL must not exceed EARLYOOM_TERM'
    if [[ $action == apply ]]; then
        if ! command_exists earlyoom; then
            if command_exists apt-get; then apt-get install --yes earlyoom
            elif command_exists dnf; then dnf install --assumeyes earlyoom
            elif command_exists pacman; then pacman -S --needed --noconfirm earlyoom
            else die 'Install the earlyoom package for this distribution'; fi
        fi
    fi
    EARLYOOM_BINARY=$(command -v earlyoom || true)
    [[ $EARLYOOM_BINARY =~ ^/[A-Za-z0-9_./-]+$ ]] || die 'Install earlyoom before dry-run; apply installs it automatically'
    stage=$(mktemp -d)
    trap '[[ -z $stage ]] || rm -r -- "$stage"' EXIT
    mkdir "$stage/earlyoom.service.d"
    cp -L "$(systemctl show earlyoom.service -p FragmentPath --value)" "$stage/earlyoom.service"
    render_config > "$stage/earlyoom.service.d/90-configfiles-earlyoom.conf"
    cat "$stage/earlyoom.service.d/90-configfiles-earlyoom.conf"
    SYSTEMD_UNIT_PATH="$stage:" systemd-analyze verify --man=no --recursive-errors=no "$stage/earlyoom.service"
    if [[ $action == apply ]]; then
        remove_legacy
        install -D -m 644 "$stage/earlyoom.service.d/90-configfiles-earlyoom.conf" "$DESTINATION/$DROPIN"
        systemctl daemon-reload
        systemctl enable earlyoom.service
        systemctl restart earlyoom.service
        systemctl is-active --quiet earlyoom.service || die 'Earlyoom failed; systemd-oomd was left unchanged'
        arguments=$(systemctl show earlyoom.service -p ExecStart --value)
        [[ $arguments == *"argv[]=$EARLYOOM_BINARY -m $EARLYOOM_TERM,$EARLYOOM_KILL -s 100,100 -g -r 3600 ;"* ]] ||
            die 'Earlyoom arguments differ; inspect systemctl cat earlyoom.service for overrides'
        for unit in systemd-oomd.service systemd-oomd.socket; do
            if [[ $(systemctl show "$unit" -p LoadState --value) != not-found ]]; then
                systemctl mask --now "$unit"
            fi
        done
        info 'Earlyoom is active with process-group killing. No new slice limits, SSH restart, or reboot.'
    fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
