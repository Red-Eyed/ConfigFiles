# ConfigFiles

## How to install

Clone repository:
`git clone https://github.com/Red-Eyed/ConfigFiles`
`./ConfigFiles/install`

Use `./ConfigFiles/install -h` to get help

For opt-in SSH resource protection on Linux servers with systemd 255+ and cgroup v2, see
[SSH availability deployment and diagnostics](docs/ssh-availability.md).
This policy is not part of the default installer.

Install SSH resilience explicitly (requests sudo and stages configuration for reboot):

```bash
./install -s install_ssh_resilience
```

Preview, inspect, or uninstall it with an explicit action after `--`:

```bash
./install -s install_ssh_resilience -- dry-run
./install -s install_ssh_resilience -- diagnose
./install -s install_ssh_resilience -- rollback
```

Pass configurable settings through the environment; the wrapper forwards these
settings through sudo:

```bash
RESERVE_CORES=2 MEMORY_HIGH=75 MEMORY_MAX=85 ./install -s install_ssh_resilience -- dry-run
```

