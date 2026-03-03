# Minecrak Dev Launcher (macOS)

A polished, terminal-based, fully Gradle-driven Minecraft multi-loader development launcher.

## Features

- Loader selection: Fabric, Quilt, NeoForge
- Clones official template repos into self-contained instances
- Per-instance config (`username`, `RAM`)
- Central `mods_library/` per instance
- Auto sync mods into runtime mods folder before launch
- Launches only with `./gradlew runClient`
- RAM injected via `GRADLE_OPTS`
- Run log capture to `logs/`
- Crash detection and copy to `crash/`
- Desktop `.command` shortcuts for each instance
- macOS dialogs (`osascript`) for mod file import and optional install location

## Instance Layout

Each instance is created as:

- `project/` (cloned Gradle project)
- `mods_library/`
- `logs/`
- `crash/`
- `config/` (`ram.conf`, `username.conf`, `loader.conf`)
- `start.command`

## Requirements

- macOS
- `python3`
- `git`
- Java + Gradle wrapper support for chosen template projects

## Usage

Recommended one-line install/bootstrap:

```bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/youraverageazurecosplay-png/Minecrak/main/Minecrak.command)"
```

This bootstrap command clones/updates the repo into `~/Minecrak`, runs the interactive installer, then optionally launches the app.

Manual first run:

```bash
cd /Users/ps/Minecrak
./install.command
```

`install.command` now asks whether you want it to install dependencies (`git`, `python`, `openjdk`) or skip package installation.

Then launch:

```bash
cd /Users/ps/Minecrak
python3 main.py
```

Or:

```bash
cd /Users/ps/Minecrak
./start.command
```

Direct launch for an existing instance:

```bash
python3 main.py --start-instance <instance_name>
```

Optional custom instances root:

```bash
python3 main.py --instances-dir ~/MinecrakInstances
```

## Main Folder Location

- Main project folder: `/Users/ps/Minecrak`
- Instances folder: `/Users/ps/Minecrak/instances`

You can also view the active instances path in the app via `Show Instances Folder Path`.

## Notes

- NeoForge template defaults to `https://github.com/NeoForged/MDK.git`.
- Username is passed as `-Pusername=<name>` and exported as `MINECRAK_USERNAME`.
- All runtime behavior stays transparent and IDE-compatible because every instance is a regular Gradle project.
