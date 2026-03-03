import subprocess
from pathlib import Path


def _run_osascript(script: str) -> str | None:
    try:
        out = subprocess.check_output(["osascript", "-e", script], text=True).strip()
        return out or None
    except subprocess.CalledProcessError:
        return None


def choose_install_location(default_path: Path) -> Path:
    script = (
        'set chosenFolder to choose folder with prompt "Select install location for Minecrak instances" default location '
        f'POSIX file "{default_path.as_posix()}/"\n'
        'POSIX path of chosenFolder'
    )
    selected = _run_osascript(script)
    return Path(selected).expanduser() if selected else default_path


def choose_mod_files() -> list[Path]:
    script = (
        'set selectedFiles to choose file with prompt "Select mod jars" of type {"jar"} '
        'with multiple selections allowed\n'
        'set outList to {}\n'
        'repeat with f in selectedFiles\n'
        'set end of outList to POSIX path of f\n'
        'end repeat\n'
        'set AppleScript\'s text item delimiters to "\\n"\n'
        'outList as string'
    )
    selected = _run_osascript(script)
    if not selected:
        return []
    return [Path(line) for line in selected.splitlines() if line.strip()]
