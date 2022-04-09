#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from argparse import ArgumentParser
from pathlib import Path

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--src", required=True, type=Path)
    parser.add_argument("--dst", required=True, type=Path)
    parser.add_argument("--force", "-f", action="store_true")

    args = parser.parse_args()

    src: Path = args.src.resolve().absolute()
    dst: Path = args.dst.resolve().absolute()

    for src_f in src.rglob("*"):
        dst_f = Path(src_f.as_posix().replace(src.as_posix(), dst.as_posix()))
        if dst_f.is_dir():
            dst_f.mkdir(exist_ok=True, parents=True)
        else:
            dst_f.parent.mkdir(exist_ok=True, parents=True)

        if dst_f.is_symlink():
            dst_f.unlink()

        if dst_f.exists():
            msg = f"{dst_f} already exists!"
            msg += " {}"
            if args.force:
                msg = msg.format("Overwriting.")
                dst_f.rename(dst_f.as_posix() + ".backup")
                dst_f.link_to(src_f)
            else:
                msg = msg.format("Skipping.")

            print(msg)
        else:
            dst_f.symlink_to(src_f)


