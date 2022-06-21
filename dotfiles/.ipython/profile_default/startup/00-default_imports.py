import sys
import os
from pathlib import Path
import importlib

modules = [
    "numpy as np",
    "torch",
    "pandas as pd",
    "cv2"
]

for m in modules:
    module_map = m.split(" as ")
    if len(module_map) == 1:
        module_name = module_map[0]
        module_ref = module_name
    else:
        module_name = module_map[0]
        module_ref = module_map[1]

    try:
        globals()[module_ref] = importlib.import_module(module_name)
    except ModuleNotFoundError:
        print(f"Cannot import {m}")

