# ConfigFiles

## How to install

Clone repository:
`git clone https://github.com/Red-Eyed/ConfigFiles`
`./ConfigFiles/install`

Use `./ConfigFiles/install -h` to get help

The launcher requires only Python 3 and defaults to headless installation on
servers. Select a script with `-s`; pass its arguments after `--`:

```bash
./install -s install_ssh_resilience -- diagnose
```

For Docker/Podman builds running as root, explicitly enable the bundled sudo shim:

```bash
./install --force_superuser
```

The Python launcher lives in `installer/`: `cli.py` parses arguments,
`scripts.py` discovers shell installers, and `runner.py` manages execution.
Run its isolated tests with `uv run --with pytest pytest installer/tests`.

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
./install -s install_ssh_resilience -- uninstall
```

Pass configurable settings through the environment; the wrapper forwards these
settings through sudo:

```bash
RESERVE_CORES=2 MEMORY_HIGH=75 MEMORY_MAX=85 ./install -s install_ssh_resilience -- dry-run
```

This installs two systemd slice drop-ins only; it does not change SSH settings.
If you installed the previous version, run `-- uninstall` first. If that policy
was already active, reboot after removal before installing the new version.

