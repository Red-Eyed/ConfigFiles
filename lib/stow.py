#!/usr/bin/env python3

import argparse
import shutil
from pathlib import Path


def copy_file(src: Path, dst: Path, force: bool, dry_run: bool) -> None:
    if dst.exists():
        if force:
            backup_path = dst.with_suffix(dst.suffix + ".bak")
            if dry_run:
                print(f"[DRY RUN] Backup: {dst} → {backup_path}")
            else:
                dst.rename(backup_path)
                print(f"Backed up: {dst} → {backup_path}")
        else:
            print(f"Skipping (exists): {dst}")
            return

    if dry_run:
        print(f"[DRY RUN] Copy: {src} → {dst}")
    else:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"Copied: {dst} ← {src}")


def copy_directory(src_dir: Path, dst_dir: Path, force: bool, dry_run: bool) -> None:
    for path in src_dir.rglob("*"):
        if path.is_file():
            relative_path = path.relative_to(src_dir)
            target = dst_dir / relative_path
            copy_file(path, target, force, dry_run)


def stow(src: Path, dst: Path, force: bool, dry_run: bool) -> None:
    if not src.exists():
        raise FileNotFoundError(f"Source path does not exist: {src}")

    if src.is_file():
        copy_file(src.resolve(), dst.resolve(), force, dry_run)
    elif src.is_dir():
        copy_directory(src.resolve(), dst.resolve(), force, dry_run)
    else:
        raise ValueError(f"Unsupported source type: {src}")


def main():
    parser = argparse.ArgumentParser(description="Copy files like stow (no symlinks)")
    parser.add_argument("--src", type=Path, help="Source file or directory to copy")
    parser.add_argument("--dst", type=Path, help="Destination directory or file")

    parser.add_argument(
        "--force",
        action="store_true",
        help="Backup and overwrite if destination exists",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without making them",
    )

    args = parser.parse_args()
    stow(args.src, args.dst, args.force, args.dry_run)


if __name__ == "__main__":
    main()
