import os
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

from .constants import INSTANCES_DIR, LOADER_TEMPLATES, ROOT_DIR


@dataclass
class InstancePaths:
    root: Path
    project: Path
    mods_library: Path
    logs: Path
    crash: Path
    config: Path
    start_command: Path


def sanitize_name(name: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9._-]", "_", name.strip())
    return cleaned[:64]


def get_instance_paths(name: str, base_dir: Path | None = None) -> InstancePaths:
    base = base_dir or INSTANCES_DIR
    root = base / name
    return InstancePaths(
        root=root,
        project=root / "project",
        mods_library=root / "mods_library",
        logs=root / "logs",
        crash=root / "crash",
        config=root / "config",
        start_command=root / "start.command",
    )


def ensure_base_dirs(base_dir: Path | None = None):
    (base_dir or INSTANCES_DIR).mkdir(parents=True, exist_ok=True)


def list_instances(base_dir: Path | None = None) -> list[str]:
    ensure_base_dirs(base_dir)
    base = base_dir or INSTANCES_DIR
    names = [p.name for p in base.iterdir() if p.is_dir() and (p / "project").exists()]
    return sorted(names)


def read_text(path: Path, default: str = "") -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except FileNotFoundError:
        return default


def write_text(path: Path, value: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value.strip() + "\n", encoding="utf-8")


def create_instance(name: str, loader: str, username: str, ram_mb: int, base_dir: Path | None = None):
    loader_key = loader.lower().strip()
    if loader_key not in LOADER_TEMPLATES:
        raise ValueError(f"Unsupported loader '{loader}'")

    safe_name = sanitize_name(name)
    if not safe_name:
        raise ValueError("Instance name is empty after sanitization")

    ensure_base_dirs(base_dir)
    paths = get_instance_paths(safe_name, base_dir)
    if paths.root.exists():
        raise FileExistsError(f"Instance '{safe_name}' already exists")

    for p in [paths.root, paths.mods_library, paths.logs, paths.crash, paths.config]:
        p.mkdir(parents=True, exist_ok=True)

    repo_url = LOADER_TEMPLATES[loader_key]
    try:
        subprocess.run(
            ["git", "clone", "--depth", "1", repo_url, str(paths.project)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        shutil.rmtree(paths.root, ignore_errors=True)
        stderr = (exc.stderr or "").strip()
        raise RuntimeError(f"Failed to clone template: {stderr}") from exc

    write_text(paths.config / "username.conf", username)
    write_text(paths.config / "ram.conf", str(ram_mb))
    write_text(paths.config / "loader.conf", loader_key)

    _write_start_command(paths, safe_name)
    _write_desktop_shortcut(safe_name)

    return safe_name, paths


def _write_start_command(paths: InstancePaths, name: str):
    content = f"""#!/bin/zsh
set -e
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
python3 "{(ROOT_DIR / 'main.py').as_posix()}" --start-instance "{name}" --instances-dir "{paths.root.parent.as_posix()}"
"""
    paths.start_command.write_text(content, encoding="utf-8")
    os.chmod(paths.start_command, 0o755)


def _write_desktop_shortcut(name: str):
    desktop = Path.home() / "Desktop"
    desktop.mkdir(parents=True, exist_ok=True)
    shortcut = desktop / f"Minecrak-{name}.command"
    content = f"""#!/bin/zsh
python3 "{(ROOT_DIR / 'main.py').as_posix()}" --start-instance "{name}"
"""
    shortcut.write_text(content, encoding="utf-8")
    os.chmod(shortcut, 0o755)


def update_instance_config(name: str, username: str | None = None, ram_mb: int | None = None, base_dir: Path | None = None):
    paths = get_instance_paths(name, base_dir)
    if not paths.root.exists():
        raise FileNotFoundError(f"Instance '{name}' does not exist")
    if username is not None:
        write_text(paths.config / "username.conf", username)
    if ram_mb is not None:
        write_text(paths.config / "ram.conf", str(ram_mb))


def delete_instance(name: str, base_dir: Path | None = None):
    paths = get_instance_paths(name, base_dir)
    if not paths.root.exists():
        raise FileNotFoundError(f"Instance '{name}' does not exist")
    shutil.rmtree(paths.root)
