#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

lib_dir = Path(__file__).parent
scripts = sorted(lib_dir.glob("*.sh"))

if not scripts:
    print("No .sh files found.")
    sys.exit(0)

failed = []
for script in scripts:
    result = subprocess.run(["shellcheck", "--external-sources", str(script)])
    if result.returncode != 0:
        failed.append(script.name)

if failed:
    print(f"\nFailed: {', '.join(failed)}")
    sys.exit(1)
else:
    print("\nAll scripts passed.")
