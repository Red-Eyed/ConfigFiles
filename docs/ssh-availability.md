# SSH resilience

Two native systemd drop-ins reserve resources for system services while limiting
ordinary user sessions. There is no custom daemon, recovery framework, or new
configuration database. Etckeeper remains the history of `/etc` changes.

## Install

Requires Linux with systemd 255+, unified cgroup v2, and systemd-oomd installed.

```bash
./install -s install_ssh_resilience -- dry-run
./install -s install_ssh_resilience
```

The installer validates the generated units using `systemd-analyze verify` and
writes only:

- `/etc/systemd/system/user.slice.d/90-ssh-availability.conf`
- `/etc/systemd/system/system.slice.d/90-ssh-availability.conf`

It does **not** reload systemd, restart SSH, change live limits, or reboot.
The policy is picked up at the next reboot. An administrator's later daemon
reload may pick up resource changes earlier, so coordinate configuration work.

SSH authentication, ports, daemon limits, OOM scores, and hardware watchdogs
are unchanged. There is no automatic rollback timer. Console/BMC access is
still the recovery path if the host cannot accept a login.

## What it does

- Excludes whole physical cores, including online SMT siblings, from `user.slice`.
  System services can use those cores. Other system activity may still compete.
- Applies aggregate user memory, swap, and task limits.
- Uses native systemd-oomd to kill eligible user cgroups under pressure.
- Gives system services higher relative CPU and I/O weights. I/O weighting is
  best-effort and depends on the device and scheduler.

Login shells share `user.slice` with workloads. A full memory or task limit can
still block shell startup. This policy does not guarantee SSH availability and
is not a security boundary against root or workloads outside `user.slice`.
It cannot prevent kernel, hardware, storage, or network failures.

## Parameters

```bash
RESERVE_CORES=2 MEMORY_HIGH=75 MEMORY_MAX=85 \
  ./install -s install_ssh_resilience -- dry-run
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `RESERVE_CORES` | `1` | Physical cores excluded from user workloads |
| `MEMORY_HIGH` | `80` | User reclaim threshold, percent of physical RAM |
| `MEMORY_MAX` | `90` | User memory ceiling, percent of physical RAM |
| `SWAP_PERCENT` | `50` | User swap ceiling, percent of currently configured swap |
| `TASKS_PERCENT` | `50` | User task ceiling, percent of system capacity |
| `PRESSURE` | `40` | Sustained memory PSI threshold used by oomd |

At least one physical core must remain for workloads, and at least 2 GiB RAM
must remain outside the user ceiling. On smaller hosts lower `MEMORY_MAX`.
Existing administrator CPU restrictions require review rather than being
silently widened. Regenerate after CPU topology or swap changes.

## Upgrade from the previous version

The old version also installed SSH, oomd, and optional watchdog drop-ins.
Remove those before installing this simpler version:

```bash
./install -s install_ssh_resilience -- uninstall
```

Uninstall recognizes the old files using the saved copies in
`/var/lib/ssh-availability/installed/`. It refuses changed or unrelated files;
review those with etckeeper. The old state is retained for reference.

If the old policy was already active, reboot **after uninstalling** to clear its
live limits and inherited SSH process settings. If it was only staged, removal
does not require reboot. No live values are guessed or replayed.

## Check and uninstall

```bash
./install -s install_ssh_resilience -- diagnose
./install -s install_ssh_resilience -- uninstall
```

After activation, inspect the effective CPU/memory/task limits, confirm oomd is
running, and test a fresh SSH connection. `sudo oomctl` shows oomd monitoring.
Check OOM events with `sudo journalctl -k -b --grep='oom|Out of memory'`.
A running SSH daemon alone does not prove that a new shell can start.

Uninstall removes owned files only. It does not change services or live limits;
reboot if the policy was already active. `rollback` remains an alias.

The independent `-- remove-obsolete` action removes the old VLC resume service
and reloads systemd; it does not restart SSH.

## Development checks

```bash
bash tests/ssh_availability/check.sh
shellcheck -x -P lib -P . lib/ssh_availability.sh lib/install_ssh_resilience.sh
```

Reference: [systemd resource controls](https://www.freedesktop.org/software/systemd/man/255/systemd.resource-control.html)
and [systemd-oomd](https://www.freedesktop.org/software/systemd/man/255/systemd-oomd.service.html).
