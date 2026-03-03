import os
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

from .instance_manager import get_instance_paths, read_text


def run_client(instance_name: str, base_dir: Path | None = None) -> tuple[int, Path, Path | None]:
    paths = get_instance_paths(instance_name, base_dir)
    if not paths.project.exists():
        raise FileNotFoundError(f"Project path missing for '{instance_name}'")

    username = read_text(paths.config / "username.conf", "DevUser")
    ram_mb = int(read_text(paths.config / "ram.conf", "4096"))

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = paths.logs / f"run_{timestamp}.log"
    paths.logs.mkdir(parents=True, exist_ok=True)
    paths.crash.mkdir(parents=True, exist_ok=True)

    gradlew = paths.project / "gradlew"
    if not gradlew.exists():
        raise FileNotFoundError(f"gradlew not found in {paths.project}")

    env = os.environ.copy()
    env["GRADLE_OPTS"] = f"-Xmx{ram_mb}m -Xms512m"
    env["MINECRAK_USERNAME"] = username

    cmd = [str(gradlew), "runClient", f"-Pusername={username}"]

    with log_file.open("w", encoding="utf-8") as log:
        proc = subprocess.Popen(
            cmd,
            cwd=paths.project,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        assert proc.stdout
        for line in proc.stdout:
            print(line, end="")
            log.write(line)
        code = proc.wait()

    crash_copy = None
    if code != 0:
        crash_copy = paths.crash / f"crash_{timestamp}.log"
        shutil.copy2(log_file, crash_copy)

    return code, log_file, crash_copy
