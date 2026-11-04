# ConfigFiles

## How to install

Clone repository:
`git clone https://github.com/Red-Eyed/ConfigFiles`
`./ConfigFiles/install`

Use `./ConfigFiles/install -h` to get help

The launcher requires only Python 3 and defaults to headless installation on
servers. Select a script with `-s`; pass its arguments after `--`:

```bash
./install -s install_earlyoom -- diagnose
```

For Docker/Podman builds running as root, explicitly enable the bundled sudo shim:

```bash
./install --force_superuser
```

The Python launcher lives in `installer/`: `cli.py` parses arguments,
`scripts.py` discovers shell installers, and `runner.py` manages execution.
Run its isolated tests with `uv run --with pytest pytest installer/tests`.

Configure earlyoom for Python multiprocessing workloads:

```bash
./install -s install_earlyoom
```

Preview, inspect, or uninstall it with an explicit action after `--`:

```bash
./install -s install_earlyoom -- dry-run
./install -s install_earlyoom -- diagnose
./install -s install_earlyoom -- uninstall
```

Pass configurable settings through the environment; the wrapper forwards these
settings through sudo:

```bash
EARLYOOM_TERM=20 EARLYOOM_KILL=15 ./install -s install_earlyoom
```

This starts earlyoom with process-group killing and RAM-based thresholds.
No custom slice limits or SSH restart.
`install_ssh_resilience` remains an alias and removes its old owned drop-ins.
See [earlyoom setup and migration](docs/earlyoom.md).

