# Earlyoom for multiprocessing workloads

```bash
./install -s install_earlyoom
```

This configures and starts the distribution's earlyoom service immediately.
It creates one service drop-in and masks
systemd-oomd's service/socket so there is one userspace OOM killer. No custom
slice policy, SSH restart, or reboot is needed for earlyoom.

Earlyoom sends SIGTERM to the selected **process group** at 20% available
userspace memory and SIGKILL at 15%. Free swap does not delay either action:

```text
earlyoom -m 20,15 -s 100,100 -g -r 3600
```

Python workers normally inherit their job's PGID. Workers using a different
PGID may survive, and other processes sharing the selected group may be killed.
Inspect groups with `ps -eo pid,ppid,pgid,rss,args --sort=-rss`. This protects the
host by terminating workloads; it does not fix memory duplication or guarantee
SSH availability during every failure.

## Options and commands

```bash
EARLYOOM_TERM=20 EARLYOOM_KILL=15 ./install -s install_earlyoom
./install -s install_earlyoom -- dry-run
./install -s install_earlyoom -- diagnose
./install -s install_earlyoom -- uninstall
```

Only the two memory thresholds are configurable. KILL must not exceed TERM.
Apply installs a missing package using apt, dnf, or pacman. Preview requires
that earlyoom is already installed so the native systemd parser can validate
its service. Linux with systemd is required.

The managed file is:

```text
/etc/systemd/system/earlyoom.service.d/90-configfiles-earlyoom.conf
```

Uninstall removes our drop-in and restarts an active earlyoom with package
defaults. The package stays installed/enabled. It unmasks systemd-oomd without
starting/enabling it.

## Migration from SSH resilience

`install_ssh_resilience` remains an alias for this command. Applying or
uninstalling removes the old ConfigFiles slice drop-ins. Systemd reloads the
remaining native configuration. Unrelated or modified legacy files are refused.

The original SSH/oomd/watchdog overrides are recognized by their saved copies
under `/var/lib/ssh-availability/installed/`. Their state is left for reference.
If the original SSH process limits/OOM scores or watchdog were already active,
removing files cannot undo settings inherited by existing processes or the
running watchdog. Those may need a one-time process restart or reboot; the
installer reports their removal and does not restart SSH automatically.

## Verify

```bash
systemctl status earlyoom.service
systemctl show earlyoom.service -p ExecStart
systemctl is-enabled systemd-oomd.service
sudo journalctl -u earlyoom.service --since '1 hour ago'
```

Expected: earlyoom is active with `-g`, `-m 20,15`, and `-s 100,100`;
systemd-oomd is masked. No destructive stress test runs automatically.

Development checks:

```bash
bash tests/earlyoom/check.sh
shellcheck -x -P lib -P . lib/install_earlyoom.sh lib/install_ssh_resilience.sh
```

Reference: [earlyoom options](https://github.com/rfjakob/earlyoom/blob/master/MANPAGE.md).
