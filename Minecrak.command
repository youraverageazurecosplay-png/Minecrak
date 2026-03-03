#!/usr/bin/env bash
set -uo pipefail

# =========================
# PORTABLE DIRECTORIES
# =========================

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_DIR="$BASE_DIR/core"
INSTANCES_DIR="$BASE_DIR/instances"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

mkdir -p "$CORE_DIR/worlds"
mkdir -p "$CORE_DIR/config/fabric"
mkdir -p "$CORE_DIR/config/quilt"
mkdir -p "$CORE_DIR/config/forge"
mkdir -p "$CORE_DIR/config/neoforge"
mkdir -p "$INSTANCES_DIR"

pause() { read -r -p "Press ENTER to continue..." _; }

# =========================
# DEPENDENCIES
# =========================

install_homebrew() {
  echo -e "${YELLOW}Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_dependencies() {
  echo
  echo "=== Dependency Check ==="
  echo

  # Git
  if ! command -v git &>/dev/null; then
    echo "Installing git..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      command -v brew >/dev/null || install_homebrew
      brew install git
    elif command -v apt &>/dev/null; then
      sudo apt update && sudo apt install -y git
    fi
  else
    echo "git OK"
  fi

  # Curl
  if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    if command -v apt &>/dev/null; then
      sudo apt install -y curl
    fi
  else
    echo "curl OK"
  fi

  # Java
  if ! command -v java &>/dev/null; then
    echo "Installing OpenJDK 21..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      command -v brew >/dev/null || install_homebrew
      brew install openjdk@21
    elif command -v apt &>/dev/null; then
      sudo apt install -y openjdk-21-jdk
    fi
  else
    echo "Java detected:"
    java -version
  fi

  pause
}

# =========================
# LOADER SELECTION
# =========================

select_loader() {
  echo
  echo "Select Loader:"
  echo "1) Fabric"
  echo "2) Quilt"
  echo "3) Forge"
  echo "4) NeoForge"
  read -rp "#? " choice

  case "$choice" in
    1) LOADER="fabric"; REPO="https://github.com/FabricMC/fabric-example-mod.git" ;;
    2) LOADER="quilt"; REPO="https://github.com/QuiltMC/quilt-template-mod.git" ;;
    3) LOADER="forge"; REPO="https://github.com/MinecraftForge/MinecraftForge.git" ;;
    4) LOADER="neoforge"; REPO="https://github.com/NeoForgeMDKs/MDK-1.21.1-NeoGradle.git" ;;
    *) return 1 ;;
  esac
}

instance_run_path() {
  if [ "$LOADER" = "neoforge" ]; then
    RUN_PATH="runs/client"
  else
    RUN_PATH="run"
  fi
}

# =========================
# INSTANCE SETUP
# =========================

create_symlinks() {
  mkdir -p "$INSTANCE_DIR/$RUN_PATH/mods"

  rm -rf "$INSTANCE_DIR/$RUN_PATH/saves"
  rm -rf "$INSTANCE_DIR/$RUN_PATH/config"

  ln -s "$CORE_DIR/worlds" "$INSTANCE_DIR/$RUN_PATH/saves"
  ln -s "$CORE_DIR/config/$LOADER" "$INSTANCE_DIR/$RUN_PATH/config"
}

create_launcher() {
  cat > "$INSTANCE_DIR/start.command" <<EOF
#!/usr/bin/env bash
cd "$INSTANCE_DIR"
USERNAME=\$(cat .username)
./gradlew runClient --args="--username \$USERNAME"
EOF

  chmod +x "$INSTANCE_DIR/start.command"
}

create_instance() {
  select_loader || return
  instance_run_path

  echo
  read -rp "Instance name: " NAME
  INSTANCE_DIR="$INSTANCES_DIR/$NAME"

  if [ -d "$INSTANCE_DIR" ]; then
    echo -e "${RED}Instance already exists.${NC}"
    pause
    return
  fi

  echo "Cloning template..."
  git clone "$REPO" "$INSTANCE_DIR" || return

  read -rp "Username [Dev]: " USERNAME
  USERNAME="${USERNAME:-Dev}"
  echo "$USERNAME" > "$INSTANCE_DIR/.username"

  create_symlinks
  create_launcher

  echo -e "${GREEN}Instance created successfully.${NC}"
  pause
}

# =========================
# INSTANCE MANAGEMENT
# =========================

list_instances() {
  echo
  echo "Instances:"
  ls "$INSTANCES_DIR"
  pause
}

launch_instance() {
  echo
  ls "$INSTANCES_DIR"
  echo
  read -rp "Instance to launch: " NAME
  TARGET="$INSTANCES_DIR/$NAME/start.command"

  if [ -f "$TARGET" ]; then
    "$TARGET"
  else
    echo "Instance not found."
  fi

  pause
}

delete_instance() {
  echo
  ls "$INSTANCES_DIR"
  echo
  read -rp "Instance to delete: " NAME

  if [ -d "$INSTANCES_DIR/$NAME" ]; then
    rm -rf "$INSTANCES_DIR/$NAME"
    echo "Deleted."
  else
    echo "Not found."
  fi

  pause
}

delete_all_instances() {
  echo
  read -rp "Type DELETE to confirm: " confirm
  if [ "$confirm" = "DELETE" ]; then
    rm -rf "$INSTANCES_DIR"
    mkdir -p "$INSTANCES_DIR"
    echo "All instances removed."
  fi
  pause
}

import_config() {
  select_loader || return
  TARGET="$CORE_DIR/config/$LOADER"
  echo
  echo "Place config files in:"
  echo "$TARGET"
  open "$TARGET" 2>/dev/null || true
  pause
}

# =========================
# FULL UNINSTALL
# =========================

full_uninstall() {
  echo
  echo -e "${RED}⚠ FULL UNINSTALL${NC}"
  echo "This will permanently delete:"
  echo "$BASE_DIR"
  echo
  read -rp "Type DELETE to confirm: " confirm

  if [ "$confirm" != "DELETE" ]; then
    echo "Cancelled."
    pause
    return
  fi

  rm -f "$HOME/Desktop/Minecrak/Minecrak Control Panel.command" 2>/dev/null || true
  rm -rf "$HOME/Desktop/Minecrak" 2>/dev/null || true
  rm -rf "$BASE_DIR"

  exit 0
}

# =========================
# MAIN MENU
# =========================

while true; do
  clear
  echo -e "${GREEN}=== Minecrak Control Panel ===${NC}"
  echo
  echo "1) Install / Check Dependencies"
  echo "2) Create Instance"
  echo "3) Launch Instance"
  echo "4) List Instances"
  echo "5) Delete Instance"
  echo "6) Delete ALL Instances"
  echo "7) Import Shared Config"
  echo "8) FULL Uninstall Minecrak"
  echo "9) Quit"
  echo
  read -rp "#? " main

  case "$main" in
    1) install_dependencies ;;
    2) create_instance ;;
    3) launch_instance ;;
    4) list_instances ;;
    5) delete_instance ;;
    6) delete_all_instances ;;
    7) import_config ;;
    8) full_uninstall ;;
    9) exit 0 ;;
  esac
done
