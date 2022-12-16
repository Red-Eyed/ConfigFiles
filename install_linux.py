#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Vadym Stupakov"
__email__ = "vadim.stupakov@gmail.com"

import os
import stat
import sys
from argparse import ArgumentParser
from pathlib import Path
from subprocess import run

ROOT_DIR = Path(__file__).absolute().parent.resolve()
ENV = os.environ.copy()

if __name__ == '__main__':
    parser = ArgumentParser(prog="install_linux.py")
    parser.add_argument("--mode", help="Installation mode", choices=["gui", "headless"], default="headless")
    parser.add_argument("--force_superuser", help="Install all from superuser. Use it for docker builds, for example",
                        action="store_true")

    args = parser.parse_args()

    env_args = {}
    for k, v in args.__dict__.items():
        if isinstance(v, bool):
            v = str(int(v))

        env_args[f"args_{k}".upper()] = v

    ENV.update(env_args)
    ENV["ROOT_DIR"] = ROOT_DIR.as_posix()

    is_superuser = os.getuid() == 0
    cmd = ["/bin/bash", (ROOT_DIR / "lib/install_linux.sh").as_posix()]

    if is_superuser:
        if args.force_superuser:
            fake_sudo = ROOT_DIR / "lib/sudo"
            fake_sudo.chmod(fake_sudo.stat().st_mode | stat.S_IEXEC)
            ENV["PATH"] = f"{fake_sudo.parent}{os.pathsep}{ENV['PATH']}"
        else:
            print("Run this script without sudo!")
            sys.exit(-1)

    try:
        ret = run(cmd, env=ENV)
        sys.exit(ret.returncode)
    except KeyboardInterrupt:
        sys.exit(0)
