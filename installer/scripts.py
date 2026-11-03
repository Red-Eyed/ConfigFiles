"""Discover runnable setup scripts without executing them."""

from pathlib import Path


def discover_scripts(root: Path) -> dict[str, Path]:
    """Return installer and uninstaller shell files keyed by name, sorted by name."""
    scripts = sorted((root / "lib").iterdir(), key=lambda path: path.name.lower())
    return {
        path.stem: path
        for path in scripts
        if path.is_file()
        and path.suffix == ".sh"
        and path.name.startswith(("install_", "uninstall_"))
    }
