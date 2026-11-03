# SSH availability on Linux servers

This opt-in policy reserves host resources for accepting SSH connections. It uses
native systemd controls and systemd-oomd; it adds no monitoring daemon and requires
no application changes. **It cannot promise 99.99% successful new logins.**
Availability must be measured externally through authentication and shell startup.

User processes, whole sessions, and background jobs may be killed by this
policy. Login shells and workloads share `user.slice`: a hard limit can block a
new shell even when sshd is healthy. CPU isolation and system memory headroom
improve the chance of recovery; they do not create reserved capacity inside that
shared user slice. A separate recovery account alone does not fix that boundary.

## Deploy

Use a maintenance window and working console/BMC access. The current SSH session
is preserved during staging. Activation requires an operator-scheduled reboot,
which terminates sessions and jobs. The utility never reboots, reloads systemd,
restarts SSH, enables a live killer, or runs a stress test.

The target needs **Linux, systemd 255+, unified cgroup v2, PSI, OpenSSH,
systemd-logind, and systemd-oomd**. Required controllers are CPU, cpuset, memory,
PIDs, and I/O. Distribution identity is not used to decide support. Standard
`ssh.service` and `sshd.service` units are discovered and aliases resolved to the
canonical unit. Per-connection `sshd@.service` instances are not supported.

On the **target host**, from the repository root:

```bash
sudo bash lib/ssh_availability.sh diagnose
sudo bash lib/ssh_availability.sh dry-run
sudo bash lib/ssh_availability.sh apply
```

If preflight reports a missing capability, install your distribution's OpenSSH
server, systemd PAM integration, and oomd packages through its approved
package-management process. Package names and package splits vary. The utility
does not install packages: their post-install scripts can start services.

`dry-run` probes the local host and writes temporary files only. It prints the
generated configuration and any differences. `apply` repeats preflight and native
parser validation before writing the same files. Neither uses a cached remote
inventory. No remote production server inspection is required for development.

Staged changes can also be picked up by a later administrator's daemon reload or
SSH restart before reboot. Coordinate other configuration management accordingly.

After the scheduled reboot, run `diagnose` again and test a **new, independent
SSH connection**. Do not consider the policy verified merely because apply passed.
Keep a second independent connection during acceptance testing.

## Parameters

Pass parameters explicitly through `sudo env`, and repeat them for dry-run/apply:

```bash
sudo env RESERVE_CORES=2 MEMORY_HIGH=75 MEMORY_MAX=85 \
  SWAP_PERCENT=40 TASKS_PERCENT=25 \
  bash lib/ssh_availability.sh dry-run
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `RESERVE_CORES` | `1` | Whole online physical cores excluded from user workloads |
| `MEMORY_HIGH` | `80` | Aggregate user reclaim threshold, percent of physical RAM |
| `MEMORY_MAX` | `90` | Aggregate user hard memory ceiling, percent of physical RAM |
| `SWAP_PERCENT` | `50` | Aggregate user swap ceiling, percent of currently configured swap |
| `TASKS_PERCENT` | `50` | Aggregate user task ceiling, percent of the smallest host task limit |
| `PRESSURE` | `40` | User memory PSI threshold for oomd, percent stalled time |
| `LOGIN_GRACE` | `60` | Seconds allowed to finish SSH authentication |
| `MAX_STARTUPS` | `20:30:80` | OpenSSH unauthenticated-connection admission policy |
| `WATCHDOG_SEC` | `0` | Disabled; nonzero requests a hardware watchdog timeout in seconds |
| `SSH_SERVICE` | auto | OpenSSH system service; aliases resolve to the canonical name |
| `SSHD_BINARY` | auto | OpenSSH daemon executable, found through PATH and standard bin/sbin paths |
| `SSHD_CONFIG` | `/etc/ssh/sshd_config` | Actual daemon configuration, including its standard drop-in Include |

Every parameter and every generated configuration directive has an adjacent
comment describing its purpose. Inspect the rendered files with `dry-run`.

Custom service wrappers, daemon flags, and alternate config files require review:
set overrides to match the daemon actually launched by systemd. The utility does
not infer arbitrary wrapper behavior or command-line `-o` overrides. The selected
SSH configuration must already include `/etc/ssh/sshd_config.d/*.conf`; it will
not edit the main configuration to add that Include.

If multiple distinct SSH services are installed, select the intended daemon with
`SSH_SERVICE=sshd.service` (or its actual unit name). Renaming the selected service
changes the owned file set, so roll back the previous selection before applying.

Percentages are integers. Leave at least one whole core for workloads. The utility
requires at least 2 GiB of RAM outside the user ceiling: defaults therefore need
at least 20 GiB usable RAM. Lower `MEMORY_MAX` on smaller machines. CPU sets, swap
bytes, and task counts are calculated at deployment, not continuously. Re-run
dry-run/apply after changing CPU topology, swap, or kernel task limits; reboot to
activate the updated policy. Physical-memory percentages adapt on systemd load.

## Installed files and behavior

Templates are in `lib/ssh_availability/`. Installation uses these owned paths:

| Path | Purpose |
| --- | --- |
| `/etc/systemd/system/user.slice.d/90-ssh-availability.conf` | User CPU, memory, swap, task, I/O, and oomd policy |
| `/etc/systemd/system/system.slice.d/90-ssh-availability.conf` | Higher relative system CPU/I/O weights |
| `/etc/systemd/system/<SSH_SERVICE>.d/90-ssh-availability.conf` | Reserved CPUs, OOM score, reclaim preference, limits, failure restart |
| `/etc/systemd/system/systemd-oomd.service.d/90-ssh-availability.conf` | Reserved CPUs and OOM score for oomd |
| `/etc/ssh/sshd_config.d/00-ssh-availability.conf` | Authentication timeout and unauthenticated connection admission |
| `/etc/systemd/system.conf.d/90-ssh-availability.conf` | Optional hardware watchdog, only when requested |

The user slice requests `systemd-oomd.service` at boot using `Wants=`. No service
enablement state is changed. Existing oomd pressure duration and global swap
thresholds are preserved; diagnostics show their effective configuration.

CPU IDs come from online `lscpu` topology. `(socket, core)` identifies each
physical core, keeping all SMT siblings together. sshd and oomd run on the reserved
set; ordinary user processes cannot run there. Other system services can use all
CPUs, including the reserved set. This excludes user CPU competition but does not
isolate interrupts, kernel threads, system services, or shared memory bandwidth.
Relative weights alone would not reserve CPU time.

`MemoryHigh` causes reclaim/throttling; `MemoryMax`, swap, and task ceilings are
hard cgroup boundaries. `MemoryLow=256M` gives sshd best-effort reclaim preference,
not preallocated memory. Parent/child limits compose: the tightest ancestor wins.
See the [systemd resource-control manual](https://www.freedesktop.org/software/systemd/man/255/systemd.resource-control.html).

oomd watches user memory pressure and global swap pressure, selecting eligible
user descendants to kill. It can kill entire sessions, including tmux. Its action
is independent of a negative kernel OOM score. Swap gives it time to react; rapid
allocation without swap can outrun it. This utility neither creates swap nor
changes swappiness, overcommit, zswap, or zram. See
[systemd-oomd manual](https://www.freedesktop.org/software/systemd/man/255/systemd-oomd.service.html).

`OOMScoreAdjust=-900` favors sshd against kernel global OOM. Portable OpenSSH can
further protect the listening daemon internally. OpenSSH restores its saved score
in children, which can inherit the service's negative value; do not interpret this
as selective protection of authentication alone. Children remain killable and
oomd/cgroup limits still apply. Inspect the listener and an actual user's score
after deployment. See [OpenSSH's Linux OOM handling](https://github.com/openssh/openssh-portable/blob/V_9_6_P1/openbsd-compat/port-linux.c).

## Exhaustion and conflicts

- **PIDs and threads:** one aggregate ceiling prevents ordinary users consuming
  all host task capacity. It counts application thread pools as well as processes.
  Reaching it can still prevent a new user session or fork. oomd does not
  react to PID exhaustion by itself. Existing per-user `TasksMax` and PAM `nproc`
  limits can fail earlier. There is no automatic PID-exhaustion killer here.
- **File descriptors:** sshd gets soft/hard `LimitNOFILE=1024:524288`, preserving
  the conventional soft limit and allowing applications to raise it. PAM may
  override inherited limits. Cgroup v2 has no aggregate open-file controller;
  these limits cannot reserve global file handles. Monitor `file-nr`/`file-max`,
  memory, and existing PAM limits. See the
  [kernel's cgroup controller documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html).
- **I/O:** user/system weights favor system services only when the device and
  scheduler implement weighted cgroup I/O. NVMe with `none`, RAID, network storage,
  and uninterruptible I/O can defeat that preference. No universal safe bandwidth
  cap is inferred. Keep authentication dependencies and root storage independent
  of workload I/O where practical; review device-specific caps after measuring.
- **Authentication floods:** `MaxStartups` starts probabilistic rejection at 20
  unauthenticated connections and rejects all at 80. Shorter authentication grace
  bounds occupancy. These limits can reject legitimate bursts, and slow MFA may
  need a longer grace period. Authentication methods, keys, ports, forwarding,
  and user access rules are preserved. This does not stop network saturation.
  See the [OpenSSH configuration manual](https://man.openbsd.org/sshd_config).
- **Session inheritance:** `TasksMax` on sshd does not cap sessions after PAM moves
  them into user scopes; the parent `user.slice` ceiling handles those. Resource
  limits set by PAM, `user@.service`, `user-.slice.d`, session scopes, containers,
  and delegated cgroups must be reviewed. Locked or device-pinned memory can reduce available
  headroom. Do not raise `memlock` globally as an availability fix.
- **Placement:** ordinary SSH logins require `UsePAM yes` and `pam_systemd`.
  Preflight follows Debian-style `@include` and session `include`/`substack`
  rules in the SSH PAM stack, with cycle detection and vendor-file fallback.
  This recognizes module presence; it cannot prove every conditional PAM path.
  See the [Linux-PAM configuration manual](https://www.man7.org/linux/man-pages/man5/pam.d.5.html).
  Check actual workload PIDs; services under `system.slice`, sudo-created system
  units, privileged containers, cron arrangements, and root jobs may escape this
  policy. It is not a security boundary against privileged users.
- **Other configuration:** existing runtime properties, later drop-ins, ancestor
  cpusets, masked services, and other oomd policies can override or tighten this
  policy. Native validation includes existing system unit drop-ins and SSH
  includes. It rejects parser errors and ineffective SSH admission settings.
  It cannot prove custom PAM behavior or future configuration-manager changes.

## Diagnostics and acceptance

```bash
sudo bash lib/ssh_availability.sh diagnose > ssh-availability-report.txt 2>&1
```

The report contains process commands and machine details; store it appropriately.
It includes topology, RAM/swap, cgroup controllers, loaded unit configuration,
effective CPU sets and memory/task limits, raw cgroup events and PSI, SSH service
and socket state, listener sockets, effective sshd settings, oomd configuration
and candidates, watchdog identity/timeout, OOM journals, session/process cgroups,
inherited limits, file-handle usage, disk capacity/inodes, and I/O schedulers.
Failed probes are labeled; this is an inspection report, not a green health check.

After reboot, confirm:

1. `/user.slice/cpuset.cpus.effective` excludes every reserved SMT sibling;
   sshd/oomd effective cpusets contain the reserved CPUs.
2. `memory.high`, `memory.max`, `memory.swap.max`, and `pids.max` contain the
   intended non-unlimited values; investigate `memory.events` and `pids.events`.
3. `oomctl` lists user memory/swap monitoring and eligible descendants. Inspect
   existing `ManagedOOMPreference` settings if candidates are unexpectedly absent.
4. Ordinary workload PIDs and a fresh shell are under `/user.slice/`; inspect
   `/proc/PID/cgroup`, `/proc/PID/limits`, and `/proc/PID/oom_score_adj` as root.
5. The discovered SSH service or its triggering socket provides the intended listener. Preserve socket
   activation if present; no port/address or socket enablement changes are made.
6. A fresh remote connection authenticates, allocates a PTY, starts a shell, and
   runs a command within your latency budget. Existing multiplexed SSH connections
   do not test this path.

## Manual stress testing

No stress command runs automatically. Start on an idle disposable server with
console access, before using a production host. Have an observer test new logins
from another machine. Install `stress-ng` only with operator approval.

First test bounded pressure as an **ordinary user**:

```bash
systemd-run --user --unit=ssh-pressure --collect \
  -p RuntimeMaxSec=120s -p MemoryHigh=1536M -p MemoryMax=2G \
  -p MemorySwapMax=256M -p TasksMax=128 -p CPUQuota=200% \
  stress-ng --cpu 2 --vm 1 --vm-bytes 2300M --vm-keep --oomable --timeout 90s
```

This confines the test process but does not prove aggregate host protection.
Even a bounded test can activate broader oomd policy if the host is already busy.
Stop it with `systemctl --user stop ssh-pressure.service` if needed.

For **extreme aggregate pressure**, use a disposable host only. Record the
generated user limits and workload CPU count, then explicitly choose `N` and
`BYTES` below. `N` should saturate the allowed workload CPUs; `BYTES` should exceed
the aggregate `MemoryMax`. This may kill all user sessions and jobs, including
the command's session. Execute only after the operator accepts that consequence:

```bash
# Replace N and BYTES with reviewed numeric values before running.
systemd-run --user --unit=ssh-extreme --collect -p RuntimeMaxSec=120s \
  stress-ng --cpu N --vm 1 --vm-bytes BYTES --vm-keep --oomable --timeout 90s
```

Observe new SSH login latency throughout CPU pressure, memory reclaim, and oomd
kills. Collect journals afterward. Test CPU-only and memory-only before combining
them. Do not add fork bombs, file-handle floods, or storage saturation to this
procedure. If new logins fail, record the failure and recover through the console;
do not automatically reboot based on one failed probe. Measure separately before
claiming any availability SLO.

## Watchdog and external monitoring

The optional `WATCHDOG_SEC` stages `RuntimeWatchdogSec` only if `/dev/watchdog0`
exists; active conventional watchdog services are rejected. Confirm the driver's
identity, supported timeout, boot behavior, and exclusive device ownership before
activation. Device detection cannot establish that it is a functioning hardware
watchdog or that no other process holds it. The utility never opens the device.

The hardware watchdog reboots if PID 1 stops servicing it; it does not test SSH,
PAM, DNS, storage, or networking. User oomd pressure relief is the first memory
recovery mechanism; sshd restarts only on service failure. Watchdog reboot is an
optional last resort for manager/system hangs. See
[systemd manager manual](https://www.freedesktop.org/software/systemd/man/255/systemd-system.conf.html).

An optional external monitor should use a dedicated ordinary account, managed
host keys, and independent SSH transports. For example, from an observer:

```bash
printf 'printf "ssh-health-ok\\n"; exit\n' | timeout 15s \
  ssh -tt -o BatchMode=yes -o ControlMaster=no -o ControlPath=none \
  -o ConnectionAttempts=1 -o ConnectTimeout=5 server.example
```

Check exit status, elapsed time, and the marker produced by the shell (allow for
PTY command echo). Schedule this on the observer with your existing monitoring
system; alert after repeated failures. Do not grant it automatic reboot powers.
Local checks cannot reliably distinguish a broken inbound network path, firewall,
external identity provider, or remote client failure. Hardware/BMC and independent
network monitoring are needed for outages the host cannot observe or survive.

## Rollback / uninstall

```bash
sudo bash lib/ssh_availability.sh rollback
```

Rollback removes only this utility's owned files and state. Pre-existing files
at those exact paths are refused during apply, so no unrelated original is
overwritten. Generated copies and the previous managed contents are kept under
`/var/lib/ssh-availability`. Repeated apply/rollback is supported. An interrupted
apply can be retried or rolled back; absent files are tolerated. Writes are
per-file, not a filesystem-wide transaction; do not reboot during deployment.

Manual edits to owned files cause apply/rollback to stop rather than discard
them. Preserve your edits elsewhere, compare them against `installed/` and
`previous/` in the state directory, then restore the matching saved file before
retrying. Roll back before toggling watchdog inclusion or selecting a different
canonical SSH service: both change the owned file set. Other parameter changes
can be applied in place.

Rollback does not remove packages, change enablement state, or change live
limits. If the policy was already loaded, schedule another reboot to remove it.
Use the console to remove these drop-ins if SSH is unavailable. Keep independent
backups of the host's existing configuration.

## Development checks

```bash
bash tests/ssh_availability/check.sh
shellcheck -x -P lib -P . lib/ssh_availability.sh tests/ssh_availability/check.sh
```

Pure tests run on macOS too. Linux adds isolated ownership/idempotency/rollback
tests; `NATIVE_VALIDATION=1` adds real systemd/sshd parser checks in a disposable
Linux environment with the required packages installed. Parser checks cover
Ubuntu 24.04 and Fedora configurations. The native test stubs only unit fragment
lookup, because that parser test does not run a system manager. These checks do
not establish runtime cgroup behavior or SSH availability under production workloads.
