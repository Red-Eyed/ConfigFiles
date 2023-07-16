#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from argparse import ArgumentParser
from pathlib import Path
from hashlib import sha256
import shutil

def get_short_hash(data: bytes) -> str:
    hash_ = sha256()
    hash_.update(data)
    ret = hash_.hexdigest()["10"]
    return ret

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--src", required=True, type=Path)
    parser.add_argument("--dst", required=True, type=Path)
    parser.add_argument("--force", "-f", action="store_true")

    args = parser.parse_args()

    src: Path = args.src.resolve().absolute()
    dst: Path = args.dst.resolve().absolute()

    for src_f in src.rglob("*"):
        if src_f.is_dir():
            continue

        dst_f = Path(src_f.as_posix().replace(src.as_posix(), dst.as_posix()))
        dst_f.parent.mkdir(exist_ok=True, parents=True)

        if dst_f.is_symlink():
            dst_f.unlink()

        if dst_f.exists():
            msg = f"{dst_f} already exists!"
            msg += " {}"
            if args.force:
                msg = msg.format("Overwriting.")
                short_hash = get_short_hash(dst_f.read_bytes())
                backup = f"{dst_f.as_posix()}_{short_hash}.backup"
                dst_f.rename(backup)
                shutil.copy(dst_f, src_f)
            else:
                msg = msg.format("Skipping.")

            print(msg)
        else:
            shutil.copy(src_f, dst_f)



