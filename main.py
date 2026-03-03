#!/usr/bin/env python3
import argparse
from pathlib import Path

from minecrak_launcher.launcher_app import LauncherApp


def parse_args():
    parser = argparse.ArgumentParser(description="Minecrak Gradle-based dev launcher")
    parser.add_argument("--start-instance", help="Start an instance directly by name")
    parser.add_argument("--instances-dir", help="Override instances directory")
    return parser.parse_args()


def main():
    args = parse_args()
    instances_dir = Path(args.instances_dir).expanduser() if args.instances_dir else None
    app = LauncherApp(instances_dir)
    if args.start_instance:
        app.launch_instance_flow(args.start_instance)
        return
    app.run()


if __name__ == "__main__":
    main()
