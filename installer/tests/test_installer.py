"""Exercise the launcher using test-owned shell scripts and environments."""

import os
import stat
from pathlib import Path

import pytest

from installer.cli import main, parse_options
from installer.runner import InstallOptions, build_environment, execute_script
from installer.scripts import discover_scripts


@pytest.fixture
def root(tmp_path: Path) -> Path:
    """Create an isolated script directory with a non-executable sudo shim."""
    library = tmp_path / "lib"
    library.mkdir()
    (library / "sudo").write_text('#!/bin/sh\nexec "$@"\n')
    (library / "sudo").chmod(0o644)
    return tmp_path


def test_discovery_filters_files(root: Path) -> None:
    """Only install/uninstall shell files participate in sorted discovery."""
    for name in ["uninstall_z.sh", "install_a.sh", "install_notes.txt", "header.sh"]:
        (root / "lib" / name).touch()
    (root / "lib" / "install_directory.sh").mkdir()
    assert list(discover_scripts(root)) == ["install_a", "uninstall_z"]


@pytest.mark.parametrize(
    ("arguments", "expected"),
    [
        ([], ()),
        (["diagnose"], ("diagnose",)),
        (["--", "diagnose"], ("diagnose",)),
        (["--", "--mode", "child", "--"], ("--mode", "child", "--")),
        (["--child", "value"], ("--child", "value")),
    ],
)
def test_forwarding(arguments: list[str], expected: tuple[str, ...]) -> None:
    """Child arguments survive parsing with and without a separator."""
    options = parse_options(arguments, "install_all_no_root")
    assert options.arguments == expected
    assert options.mode == "headless"
    assert options.script == "install_all_no_root"
    assert not options.force_superuser


def test_launcher_flags() -> None:
    """Existing explicit flags retain their meaning."""
    assert parse_options(
        ["-s", "install_custom", "--mode", "gui", "--force_superuser"], ""
    ) == InstallOptions("install_custom", "gui", True, ())


@pytest.mark.parametrize(("arguments", "status"), [(["-h"], 0), (["--mode", "bad"], 2)])
def test_parser_exits(arguments: list[str], status: int) -> None:
    """Help and invalid launcher values retain argparse exit codes."""
    with pytest.raises(SystemExit) as error:
        parse_options(arguments, "install_custom")
    assert error.value.code == status


def test_environment(root: Path) -> None:
    """Installer variables override inherited values without mutating the parent."""
    inherited = {"TOKEN": "test", "ARGS_MODE": "old"}
    options = InstallOptions("install_custom", "headless", True, ())
    assert build_environment(root, options, inherited) == {
        "TOKEN": "test",
        "ROOT_DIR": str(root),
        "ARGS_MODE": "headless",
        "ARGS_SCRIPT": "install_custom",
        "ARGS_FORCE_SUPERUSER": "1",
    }
    assert inherited == {"TOKEN": "test", "ARGS_MODE": "old"}


def test_invalid_script(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    """Unknown selections fail before execution and list available scripts."""
    (root / "lib" / "install_custom.sh").touch()
    assert main(root, ["-s", "missing"]) == 1
    assert "install_custom" in capsys.readouterr().err


def test_root_refusal(root: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    """Root refusal occurs before touching a script or sudo shim."""
    monkeypatch.setattr(os, "getuid", lambda: 0)
    options = InstallOptions("install_missing", "headless", False, ())
    assert execute_script(root, root / "missing", options) == -1
    assert not (root / "lib" / "sudo").stat().st_mode & stat.S_IXUSR


@pytest.mark.parametrize("is_root", [False, True])
def test_execution(root: Path, monkeypatch: pytest.MonkeyPatch, is_root: bool) -> None:
    """Real Bash receives exact arguments, variables, and container sudo behavior."""
    monkeypatch.setattr(os, "getuid", lambda: 0 if is_root else 1000)
    script = root / "lib" / "install_custom.sh"
    script.write_text(
        '[[ "$ARGS_SCRIPT" == install_custom ]] || exit 10\n'
        '[[ "$ARGS_MODE" == headless ]] || exit 11\n'
        '[[ "$1" == "two words" && "$2" == --flag ]] || exit 12\n'
        'if [[ "$ARGS_FORCE_SUPERUSER" == 1 ]]; then\n'
        '  [[ "$(command -v sudo)" == "$ROOT_DIR/lib/sudo" ]] || exit 13\n'
        '  sudo /bin/sh -c "exit 0" || exit 14\n'
        "fi\nexit 7\n"
    )
    previous_path = os.environ.get("PATH")
    assert (
        main(
            root,
            [
                "-s",
                "install_custom",
                *(["--force_superuser"] if is_root else []),
                "--",
                "two words",
                "--flag",
            ],
        )
        == 7
    )
    assert os.environ.get("PATH") == previous_path
