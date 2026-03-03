from pathlib import Path

from .constants import INSTANCES_DIR
from .instance_manager import (
    create_instance,
    delete_instance,
    get_instance_paths,
    list_instances,
    read_text,
    update_instance_config,
)
from .macos_dialogs import choose_install_location, choose_mod_files
from .mod_manager import add_mod_files, sync_mods
from .runner import run_client
from .ui import (
    ANSI,
    box,
    choose_from_menu,
    clear_screen,
    print_error,
    print_header,
    print_info,
    print_success,
    prompt,
    spinning,
)


class LauncherApp:
    def __init__(self, instances_dir: Path | None = None):
        self.instances_dir = (instances_dir or INSTANCES_DIR).expanduser()
        self.instances_dir.mkdir(parents=True, exist_ok=True)

    def run(self):
        while True:
            choice = choose_from_menu(
                "Main Menu",
                [
                    "Create Instance",
                    "Launch Instance",
                    "Manage Mods",
                    "Edit Instance Config",
                    "Delete Instance",
                    "Change Install Location",
                    "List Instances",
                    "Show Instances Folder Path",
                ],
            )

            if choice == 0:
                break
            if choice == 1:
                self.create_instance_flow()
            elif choice == 2:
                self.launch_instance_flow()
            elif choice == 3:
                self.manage_mods_flow()
            elif choice == 4:
                self.edit_config_flow()
            elif choice == 5:
                self.delete_instance_flow()
            elif choice == 6:
                self.change_install_location_flow()
            elif choice == 7:
                self.list_instances_flow()
            elif choice == 8:
                self.show_instances_path_flow()

    def _pick_instance(self, title: str = "Select Instance") -> str | None:
        names = list_instances(self.instances_dir)
        if not names:
            clear_screen()
            print_header("Minecrak Dev Launcher", title)
            print_error("No instances found.")
            input("Press Enter to continue...")
            return None
        idx = choose_from_menu(title, names)
        if idx == 0:
            return None
        return names[idx - 1]

    def create_instance_flow(self):
        clear_screen()
        print_header("Create Instance", f"Install dir: {self.instances_dir}")
        print(box("Loaders", ["1. Fabric", "2. Quilt", "3. NeoForge"], color="green"))

        raw = prompt("Choose loader number", "1")
        loader_map = {"1": "fabric", "2": "quilt", "3": "neoforge"}
        loader = loader_map.get(raw)
        if not loader:
            print_error("Invalid loader selection")
            input("Press Enter to continue...")
            return

        name = prompt("Instance name")
        username = prompt("Minecraft username", "DevUser")
        ram_str = prompt("RAM in MB", "4096")
        if not ram_str.isdigit() or int(ram_str) < 1024:
            print_error("RAM must be a number >= 1024")
            input("Press Enter to continue...")
            return

        try:
            with spinning(f"Cloning {loader} template"):
                created_name, paths = create_instance(name, loader, username, int(ram_str), self.instances_dir)
            print_success(f"Instance '{created_name}' created at {paths.root}")
            print_info("Desktop shortcut generated.")
        except Exception as exc:
            print_error(str(exc))
        input("Press Enter to continue...")

    def launch_instance_flow(self, instance: str | None = None):
        name = instance or self._pick_instance("Launch Instance")
        if not name:
            return
        clear_screen()
        print_header("Launch Instance", name)
        try:
            copied, run_mods = sync_mods(name, self.instances_dir)
            print_info(f"Synced {copied} mod(s) to {run_mods}")
            print(ANSI["dim"] + "Starting Gradle runClient..." + ANSI["reset"])
            code, log_file, crash_copy = run_client(name, self.instances_dir)
            if code == 0:
                print_success(f"Minecraft exited normally. Log: {log_file}")
            else:
                print_error(f"Minecraft crashed with exit code {code}")
                if crash_copy:
                    print_error(f"Crash log copied to: {crash_copy}")
        except Exception as exc:
            print_error(str(exc))
        input("Press Enter to continue...")

    def manage_mods_flow(self):
        name = self._pick_instance("Manage Mods")
        if not name:
            return
        clear_screen()
        print_header("Manage Mods", name)

        files = choose_mod_files()
        if not files:
            print_info("No files selected.")
            input("Press Enter to continue...")
            return

        try:
            copied = add_mod_files(name, files, self.instances_dir)
            print_success(f"Added {copied} mod(s) to mods_library")
        except Exception as exc:
            print_error(str(exc))
        input("Press Enter to continue...")

    def edit_config_flow(self):
        name = self._pick_instance("Edit Config")
        if not name:
            return
        paths = get_instance_paths(name, self.instances_dir)
        current_user = read_text(paths.config / "username.conf", "DevUser")
        current_ram = read_text(paths.config / "ram.conf", "4096")

        clear_screen()
        print_header("Edit Config", name)
        username = prompt("Username", current_user)
        ram_str = prompt("RAM in MB", current_ram)
        if not ram_str.isdigit() or int(ram_str) < 1024:
            print_error("RAM must be a number >= 1024")
            input("Press Enter to continue...")
            return

        try:
            update_instance_config(name, username=username, ram_mb=int(ram_str), base_dir=self.instances_dir)
            print_success("Configuration updated.")
        except Exception as exc:
            print_error(str(exc))
        input("Press Enter to continue...")

    def delete_instance_flow(self):
        name = self._pick_instance("Delete Instance")
        if not name:
            return
        confirm = prompt(f"Type '{name}' to confirm deletion")
        if confirm != name:
            print_info("Delete canceled.")
            input("Press Enter to continue...")
            return
        try:
            delete_instance(name, self.instances_dir)
            print_success(f"Deleted instance '{name}'")
        except Exception as exc:
            print_error(str(exc))
        input("Press Enter to continue...")

    def change_install_location_flow(self):
        clear_screen()
        print_header("Install Location")
        selected = choose_install_location(self.instances_dir)
        self.instances_dir = selected
        self.instances_dir.mkdir(parents=True, exist_ok=True)
        print_success(f"Using install location: {self.instances_dir}")
        input("Press Enter to continue...")

    def list_instances_flow(self):
        names = list_instances(self.instances_dir)
        clear_screen()
        print_header("Instances", f"Install dir: {self.instances_dir}")
        if not names:
            print(box("Instances", ["No instances available."], color="yellow"))
        else:
            print(box("Instances", names, color="green"))
        input("Press Enter to continue...")

    def show_instances_path_flow(self):
        clear_screen()
        print_header("Instances Folder")
        print(box("Path", [str(self.instances_dir)], color="green"))
        input("Press Enter to continue...")
