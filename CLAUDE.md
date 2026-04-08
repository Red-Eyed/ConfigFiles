# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles and system-setup repository. It installs shell configs, tools, and system settings on Linux machines (Debian/Ubuntu and Arch).

## Entry point

```bash
./install                          # run default installer (install_all_no_root)
./install -s install_apt_headless  # run a specific script
./install --mode gui               # headless (default) or gui
./install --force_superuser        # for Docker/root environments
./install -h                       # full help
```

`install` is a Python 3 script that discovers all `lib/install_*.sh` scripts, sets `ROOT_DIR` and `args_*` environment variables, then executes the chosen script via `/bin/bash`.

## Linting bash scripts

```bash
python3 lib/check.py   # runs shellcheck --external-sources on all lib/*.sh
```

## Architecture

```
install              # Python entry point — arg parsing, env setup, dispatch
lib/
  header.sh          # sourced by every install script; defines shared helpers
  install_*.sh       # individual installers, each self-contained
  stow.py            # copies dotfiles/ tree into $HOME (with .bak backups)
  check.py           # runs shellcheck on all *.sh files
  sudo               # fake sudo stub (used when running as root in Docker)
  systemd_units/     # unit files copied to /etc/systemd/system/ by configure_systemd.sh
  etc/               # config files deployed by configure_systemd.sh
  sysfs.d/           # sysfs config (zswap)
dotfiles/            # deployed verbatim to $HOME by install_dotfiles.sh via stow.py
```

## Shared bash helpers (lib/header.sh)

Every `install_*.sh` sources `header.sh` which provides:

| Function | Purpose |
|---|---|
| `file_exists path` | `[[ -f path ]]` |
| `dir_exists path` | `[[ -d path ]]` |
| `command_exists cmd` | `command -v cmd >/dev/null 2>&1` |
| `is_root` | true if EUID == 0 |
| `info/warn/error msg` | labelled output (warn/error go to stderr) |
| `die msg` | error + exit 1 |
| `download url dest` | curl with `--proto '=https' --tlsv1.2` |

## Bash script conventions

- All scripts start with `cd "$(dirname "$(readlink -f "$0")")" || exit` to ensure relative paths work.
- Scripts source `header.sh` with `# shellcheck source=header.sh` directive immediately after.
- Package lists use bash arrays (`packages=(...)`) with `"${packages[@]}"` — never unquoted strings.
- `install_all_no_root.sh` is the default: runs without sudo, installs language runtimes and dotfiles.
- `install_all.sh` additionally runs `install_apt_headless.sh` (requires sudo).

## Environment variables set by `install`

| Variable | Value |
|---|---|
| `ROOT_DIR` | absolute path to repo root |
| `ARGS_SCRIPT` | selected script name |
| `ARGS_MODE` | `headless` or `gui` |
| `ARGS_FORCE_SUPERUSER` | `0` or `1` |
