"""Translate installer options into a child process environment and execution."""

import os
import stat
import subprocess
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class InstallOptions:
    """Validated launcher settings; forwarded arguments belong to the child script."""

    script: str
    mode: str
    force_superuser: bool
    arguments: tuple[str, ...]


def build_environment(
    root: Path, options: InstallOptions, inherited: Mapping[str, str]
) -> dict[str, str]:
    """Copy the parent environment and set the shell installers' public variables."""
    return {
        **inherited,
        "ROOT_DIR": str(root),
        "ARGS_SCRIPT": options.script,
        "ARGS_MODE": options.mode,
        "ARGS_FORCE_SUPERUSER": str(int(options.force_superuser)),
    }


def execute_script(root: Path, script: Path, options: InstallOptions) -> int:
    """Run Bash and return its status; refuse root unless explicitly enabled.

    Forced root execution makes the bundled sudo shim executable and prepends its
    directory to the child's PATH. Keyboard interruption preserves the launcher's
    existing successful exit status. Other process errors propagate to the caller.
    """
    is_root = os.getuid() == 0
    if is_root and not options.force_superuser:
        print("Run this script without sudo!")
        return -1

    environment = build_environment(root, options, os.environ)
    if is_root:
        fake_sudo = root / "lib" / "sudo"
        fake_sudo.chmod(fake_sudo.stat().st_mode | stat.S_IEXEC)
        environment["PATH"] = (
            f"{fake_sudo.parent}{os.pathsep}{environment.get('PATH', os.defpath)}"
        )

    command = ["/bin/bash", str(script), *options.arguments]
    print(command, flush=True)
    try:
        return subprocess.run(command, env=environment, check=False).returncode
    except KeyboardInterrupt:
        return 0
