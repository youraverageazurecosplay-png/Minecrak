#!/usr/bin/env bash
set -uo pipefail

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
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_dependencies() {
  echo "Checking dependencies..."
  echo

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

  if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    if command -v apt &>/dev/null; then
      sudo apt install -y curl
    fi
  else
    echo "curl OK"
  fi

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
# LOADERS
# =========================

select_loader() {
  echo
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

# =========================
# INSTANCE MGMT
# =========================

create_instance() {
  select_loader || return
  instance_run_path

  read -rp "Instance name: " NAME
  INSTANCE_DIR="$INSTANCES_DIR/$NAME"

  [ -d "$INSTANCE_DIR" ] && echo "Exists." && return

  git clone "$REPO" "$INSTANCE_DIR" || return

  read -rp "Username [Dev]: " USERNAME
  USERNAME="${USERNAME:-Dev}"
  echo "$USERNAME" > "$INSTANCE_DIR/.username"

  create_symlinks
  create_launcher

  echo "Created."
  pause
}

list_instances() {
  echo
  ls "$INSTANCES_DIR"
  pause
}

launch_instance() {
  list_instances
  read -rp "Instance to launch: " NAME
  TARGET="$INSTANCES_DIR/$NAME/start.command"
  [ -f "$TARGET" ] && "$TARGET"
  pause
}

delete_instance() {
  list_instances
  read -rp "Instance to delete: " NAME
  rm -rf "$INSTANCES_DIR/$NAME"
  pause
}

delete_all_instances() {
  read -rp "Type DELETE to confirm: " confirm
  [ "$confirm" = "DELETE" ] && rm -rf "$INSTANCES_DIR" && mkdir -p "$INSTANCES_DIR"
  pause
}

import_config() {
  select_loader || return
  TARGET="$CORE_DIR/config/$LOADER"
  open "$TARGET" 2>/dev/null || true
  pause
}

full_uninstall() {
  echo
  echo "⚠ FULL UNINSTALL"
  echo "Deletes: $BASE_DIR"
  read -rp "Type DELETE to confirm: " confirm
  [ "$confirm" != "DELETE" ] && return

  rm -f "$HOME/Desktop/Minecrak.command" 2>/dev/null || true
  rm -rf "$BASE_DIR"
  exit 0
}

# =========================
# MENU
# =========================

while true; do
  clear
  echo -e "${GREEN}=== Minecrak Master ===${NC}"
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
