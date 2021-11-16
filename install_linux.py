#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Vadym Stupakov"
__email__ = "vadim.stupakov@gmail.com"

from subprocess import run
from argparse import ArgumentParser
import os
from pathlib import Path
import sys

ROOT_DIR = Path(__file__).absolute().parent.resolve()
ENV = os.environ.copy()

if __name__ == '__main__':
    parser = ArgumentParser(prog="install_linux.py")
    parser.add_argument("--mode", help="Installation mode", choices=["gui", "headless"], default="headless")

    args = parser.parse_args()

    args = {f"args_{k}".upper(): v for k, v in args.__dict__.items()}

    ENV.update(args)
    ENV["ROOT_DIR"] = ROOT_DIR.as_posix()

    try:
        ret = run(["/bin/bash", ROOT_DIR / "lib/install_linux.sh"], env=ENV)
        sys.exit(ret.returncode)
    except KeyboardInterrupt:
        sys.exit(0)


