#!/usr/bin/env bash
set -euo pipefail

print_centered() {
  local text="$1"
  local width=$(tput cols)
  printf "%*s\n" $(((${#text} + width) / 2)) "$text"
}

clear
echo -e "${GREEN}"
print_centered "███╗   ███╗██╗███╗   ██╗███████╗ ██████╗██████╗  █████╗ ██╗  ██╗"
print_centered "████╗ ████║██║████╗  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗██║ ██╔╝"
print_centered "██╔████╔██║██║██╔██╗ ██║█████╗  ██║     ██████╔╝███████║█████╔╝ "
print_centered "██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██║     ██╔══██╗██╔══██║██╔═██╗ "
print_centered "██║ ╚═╝ ██║██║██║ ╚████║███████╗╚██████╗██║  ██║██║  ██║██║  ██╗"
print_centered "╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝"
echo
print_centered "Gradle Mod Development Launcher"
print_centered "Version $VERSION"
echo -e "${NC}"
echo

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCES_DIR="$BASE_DIR/instances"
DESKTOP_DIR="$HOME/Desktop/Minecrak"
VERSION="3.0.0-Gradle"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

mkdir -p "$INSTANCES_DIR"
mkdir -p "$DESKTOP_DIR"

pause() { read -r -p "Press ENTER to continue..." _; }

clear
echo -e "${GREEN}=== Minecrak v$VERSION ===${NC}"
echo

# =========================
# DEPENDENCY CHECK
# =========================

check_dependencies() {
  for cmd in git java; do
    if ! command -v $cmd &>/dev/null; then
      echo -e "${RED}$cmd not installed.${NC}"
      echo "Please install it and retry."
      exit 1
    fi
  done
}

# =========================
# LOADER SELECT
# =========================

select_loader() {
  echo
  echo "1) Fabric"
  echo "2) Quilt"
  echo "3) Forge"
  echo "4) NeoForge"
  echo
  read -rp "Select loader: " LOADER_CHOICE

  case "$LOADER_CHOICE" in
    1)
      LOADER="fabric"
      REPO="https://github.com/FabricMC/fabric-example-mod.git"
      RUN_PATH="run"
      ;;
    2)
      LOADER="quilt"
      REPO="https://github.com/QuiltMC/quilt-template-mod.git"
      RUN_PATH="run"
      ;;
    3)
      LOADER="forge"
      REPO="https://github.com/MinecraftForge/MinecraftForge.git"
      RUN_PATH="run"
      ;;
    4)
      LOADER="neoforge"
      REPO="https://github.com/NeoForgeMDKs/MDK-1.21.1-NeoGradle.git"
      RUN_PATH="runs/client"
      ;;
    *)
      echo "Invalid choice."
      return 1
      ;;
  esac
}

# =========================
# CREATE INSTANCE
# =========================

create_instance() {
  check_dependencies
  select_loader || return

  echo
  read -rp "Instance name: " NAME
  INSTANCE_DIR="$INSTANCES_DIR/$NAME"

  if [ -d "$INSTANCE_DIR" ]; then
    echo -e "${RED}Instance already exists.${NC}"
    pause
    return
  fi

  echo "Cloning $LOADER template..."
  git clone "$REPO" "$INSTANCE_DIR"

  read -rp "Username [Dev]: " USERNAME
  USERNAME="${USERNAME:-Dev}"
  echo "$USERNAME" > "$INSTANCE_DIR/.username"

  create_start_script "$INSTANCE_DIR"
  create_desktop_launcher "$NAME"

  echo -e "${GREEN}Instance created successfully.${NC}"
  pause
}

# =========================
# START SCRIPT
# =========================

create_start_script() {
  INSTANCE_DIR="$1"

  cat > "$INSTANCE_DIR/start.command" <<EOF
#!/usr/bin/env bash
cd "$INSTANCE_DIR"
USERNAME=\$(cat .username)
./gradlew runClient --args="--username \$USERNAME"
EOF

  chmod +x "$INSTANCE_DIR/start.command"
}

# =========================
# DESKTOP LAUNCHER
# =========================

create_desktop_launcher() {
  NAME="$1"
  INSTANCE_DIR="$INSTANCES_DIR/$NAME"

  ln -sf "$INSTANCE_DIR/start.command" \
         "$DESKTOP_DIR/$NAME.command"
}

# =========================
# LIST INSTANCES
# =========================

list_instances() {
  echo
  ls "$INSTANCES_DIR"
  pause
}

# =========================
# LAUNCH INSTANCE
# =========================

launch_instance() {
  echo
  ls "$INSTANCES_DIR"
  echo
  read -rp "Launch which: " NAME

  if [ -f "$INSTANCES_DIR/$NAME/start.command" ]; then
    "$INSTANCES_DIR/$NAME/start.command"
  else
    echo "Instance not found."
    pause
  fi
}

# =========================
# DELETE INSTANCE
# =========================

delete_instance() {
  echo
  ls "$INSTANCES_DIR"
  echo
  read -rp "Delete which: " NAME

  rm -rf "$INSTANCES_DIR/$NAME"
  rm -f "$DESKTOP_DIR/$NAME.command"

  echo "Deleted."
  pause
}

# =========================
# UNINSTALL
# =========================

full_uninstall() {
  echo -e "${RED}Type DELETE to uninstall Minecrak:${NC}"
  read confirm
  [ "$confirm" != "DELETE" ] && return

  rm -rf "$BASE_DIR"
  rm -rf "$DESKTOP_DIR"
  echo "Minecrak removed."
  exit 0
}

# =========================
# MAIN MENU
# =========================

while true; do
  clear
  echo -e "${GREEN}=== Minecrak v$VERSION ===${NC}"
  echo
  echo "1) Create Instance"
  echo "2) Launch Instance"
  echo "3) List Instances"
  echo "4) Delete Instance"
  echo "5) Uninstall Minecrak"
  echo "6) Quit"
  echo
  read -rp "#? " opt

  case "$opt" in
    1) create_instance ;;
    2) launch_instance ;;
    3) list_instances ;;
    4) delete_instance ;;
    5) full_uninstall ;;
    6) exit 0 ;;
  esac
done
