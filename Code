#!/usr/bin/env bash
set -uo pipefail

# =========================
# DIRECTORIES
# =========================

BASE_DIR="$HOME/Minecrak"
CORE_DIR="$HOME/MinecrakCore"
INSTANCES_DIR="$HOME/MinecrakInstances"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

mkdir -p "$BASE_DIR"
mkdir -p "$CORE_DIR/worlds"
mkdir -p "$CORE_DIR/config/fabric"
mkdir -p "$CORE_DIR/config/quilt"
mkdir -p "$CORE_DIR/config/forge"
mkdir -p "$CORE_DIR/config/neoforge"
mkdir -p "$INSTANCES_DIR"

pause() { read -r -p "Press ENTER to continue..." _; }

# =========================
# DEPENDENCY INSTALLER
# =========================

install_homebrew() {
  echo -e "${YELLOW}Homebrew not found.${NC}"
  read -rp "Install Homebrew? (y/n): " ans
  if [[ "$ans" == "y" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_dependencies() {
  echo
  echo "=== System Dependency Check ==="
  echo

  # Git
  if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}git missing.${NC}"
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
    echo -e "${YELLOW}curl missing.${NC}"
    if command -v apt &>/dev/null; then
      sudo apt install -y curl
    fi
  else
    echo "curl OK"
  fi

  # Java 21
  if ! command -v java &>/dev/null; then
    echo -e "${YELLOW}Java not found.${NC}"
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

  echo -e "${GREEN}Dependency check complete.${NC}"
  pause
}

# =========================
# LOADER HANDLING
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
    *) echo "Invalid."; return 1 ;;
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
# INSTANCE MANAGEMENT
# =========================

create_instance() {
  select_loader || return
  instance_run_path

  read -rp "Instance name: " NAME
  INSTANCE_DIR="$INSTANCES_DIR/$NAME"

  if [ -d "$INSTANCE_DIR" ]; then
    echo "Instance already exists."
    return
  fi

  echo "Cloning template..."
  git clone "$REPO" "$INSTANCE_DIR" || return

  read -rp "Username [Dev]: " USERNAME
  USERNAME="${USERNAME:-Dev}"
  echo "$USERNAME" > "$INSTANCE_DIR/.username"

  create_symlinks
  create_launcher

  echo -e "${GREEN}Instance created.${NC}"
  pause
}

list_instances() {
  echo
  ls "$INSTANCES_DIR"
  pause
}

delete_instance() {
  list_instances
  read -rp "Instance to delete: " NAME
  rm -rf "$INSTANCES_DIR/$NAME"
  echo "Deleted."
  pause
}

delete_all() {
  read -rp "Type DELETE to confirm: " confirm
  if [ "$confirm" = "DELETE" ]; then
    rm -rf "$INSTANCES_DIR"
    mkdir -p "$INSTANCES_DIR"
    echo "All removed."
  fi
  pause
}

import_config() {
  select_loader || return
  TARGET="$CORE_DIR/config/$LOADER"
  echo "Place config files in:"
  echo "$TARGET"
  open "$TARGET" 2>/dev/null || true
  pause
}

# =========================
# MAIN MENU
# =========================

while true; do
  clear
  echo -e "${GREEN}=== Minecrak Master ===${NC}"
  echo
  echo "1) Install / Check Dependencies"
  echo "2) Create Instance"
  echo "3) List Instances"
  echo "4) Delete Instance"
  echo "5) Delete ALL Instances"
  echo "6) Import Shared Config"
  echo "7) Quit"
  echo
  read -rp "#? " main

  case "$main" in
    1) install_dependencies ;;
    2) create_instance ;;
    3) list_instances ;;
    4) delete_instance ;;
    5) delete_all ;;
    6) import_config ;;
    7) exit 0 ;;
    *) pause ;;
  esac
done
