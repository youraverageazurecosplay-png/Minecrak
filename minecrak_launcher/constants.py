from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
INSTANCES_DIR = ROOT_DIR / "instances"

LOADER_TEMPLATES = {
    "fabric": "https://github.com/FabricMC/fabric-example-mod.git",
    "quilt": "https://github.com/QuiltMC/quilt-template-mod.git",
    "neoforge": "https://github.com/NeoForged/MDK.git",
}

ANSI = {
    "reset": "\033[0m",
    "bold": "\033[1m",
    "cyan": "\033[92m",
    "blue": "\033[97m",
    "green": "\033[92m",
    "yellow": "\033[93m",
    "red": "\033[91m",
    "magenta": "\033[95m",
    "dim": "\033[2m",
}
