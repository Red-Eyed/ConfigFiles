"""Parse the existing installer CLI and dispatch a selected shell script."""

import sys
from argparse import ArgumentParser, RawTextHelpFormatter
from collections.abc import Sequence
from pathlib import Path

from installer.runner import InstallOptions, execute_script
from installer.scripts import discover_scripts


def parse_options(arguments: Sequence[str], scripts_help: str) -> InstallOptions:
    """Parse launcher flags, forwarding unknown arguments and everything after --.

    An explicit separator protects child flags that also exist in the launcher.
    Invalid launcher values and help use argparse's normal exit behavior.
    """
    arguments = list(arguments)
    forwarded: list[str] = []
    if "--" in arguments:
        separator = arguments.index("--")
        forwarded = arguments[separator + 1 :]
        arguments = arguments[:separator]

    parser = ArgumentParser(prog="install", formatter_class=RawTextHelpFormatter)
    parser.add_argument(
        "-s",
        "--script",
        help=f"script to run (choices are):\n  {scripts_help}",
        default="install_all_no_root",
    )
    parser.add_argument(
        "--mode",
        help="Installation mode",
        choices=["gui", "headless"],
        default="headless",
    )
    parser.add_argument(
        "--force_superuser",
        help="Install all from superuser. Use it for docker builds, for example",
        action="store_true",
    )
    parsed, unknown = parser.parse_known_args(arguments)
    return InstallOptions(
        script=parsed.script,
        mode=parsed.mode,
        force_superuser=parsed.force_superuser,
        arguments=tuple(unknown + forwarded),
    )


def main(root: Path, arguments: Sequence[str]) -> int:
    """Discover scripts and execute a selection; invalid script names return one."""
    scripts = discover_scripts(root)
    scripts_help = "\n  ".join(scripts)
    options = parse_options(arguments, scripts_help)
    if options.script not in scripts:
        print(
            f"❌ Invalid script: '{options.script}'\nAvailable choices:\n  {scripts_help}",
            file=sys.stderr,
        )
        return 1
    return execute_script(root, scripts[options.script], options)
