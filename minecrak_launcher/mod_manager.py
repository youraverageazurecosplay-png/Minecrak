import shutil
from pathlib import Path

from .instance_manager import get_instance_paths


def detect_run_mods_dir(project_dir: Path) -> Path:
    candidates = [
        project_dir / "run" / "mods",
        project_dir / "runs" / "client" / "mods",
    ]
    for path in candidates:
        if path.parent.exists() or path.exists():
            path.mkdir(parents=True, exist_ok=True)
            return path
    fallback = project_dir / "run" / "mods"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback


def sync_mods(instance_name: str, base_dir: Path | None = None) -> tuple[int, Path]:
    paths = get_instance_paths(instance_name, base_dir)
    if not paths.root.exists():
        raise FileNotFoundError(f"Instance '{instance_name}' does not exist")

    run_mods = detect_run_mods_dir(paths.project)

    for jar in run_mods.glob("*.jar"):
        jar.unlink()

    copied = 0
    for src in paths.mods_library.glob("*.jar"):
        shutil.copy2(src, run_mods / src.name)
        copied += 1
    return copied, run_mods


def add_mod_files(instance_name: str, files: list[Path], base_dir: Path | None = None) -> int:
    paths = get_instance_paths(instance_name, base_dir)
    if not paths.root.exists():
        raise FileNotFoundError(f"Instance '{instance_name}' does not exist")
    paths.mods_library.mkdir(parents=True, exist_ok=True)

    copied = 0
    for mod_file in files:
        if mod_file.suffix.lower() != ".jar":
            continue
        shutil.copy2(mod_file, paths.mods_library / mod_file.name)
        copied += 1
    return copied
