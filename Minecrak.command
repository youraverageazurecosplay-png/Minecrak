#!/usr/bin/env bash
set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_DIR="$BASE_DIR/core"
INSTANCES_DIR="$BASE_DIR/instances"
BACKUP_DIR="$BASE_DIR/backups"
VERSION_FILE="$BASE_DIR/VERSION"
VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo "DEV")"

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
mkdir -p "$BACKUP_DIR"

pause() { read -r -p "Press ENTER to continue..." _; }

clear
echo -e "${GREEN}"
echo "███╗   ███╗██╗███╗   ██╗███████╗ ██████╗██████╗  █████╗ ██╗  ██╗"
echo "████╗ ████║██║████╗  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗██║ ██╔╝"
echo "██╔████╔██║██║██╔██╗ ██║█████╗  ██║     ██████╔╝███████║█████╔╝ "
echo "██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██║     ██╔══██╗██╔══██║██╔═██╗ "
echo "██║ ╚═╝ ██║██║██║ ╚████║███████╗╚██████╗██║  ██║██║  ██║██║  ██╗"
echo "╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝"
echo -e "Minecrak v$VERSION"
echo -e "${NC}"

# =========================
# UPDATE CHECK
# =========================

check_updates() {
  REMOTE_VERSION=$(curl -fsSL https://raw.githubusercontent.com/youraverageazurecosplay-png/Minecrak/main/VERSION 2>/dev/null || echo "")
  if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$VERSION" ]; then
    echo -e "${YELLOW}Update available: $REMOTE_VERSION${NC}"
    read -rp "Update now? (y/n): " ans
    if [ "$ans" = "y" ]; then
      curl -fsSL https://raw.githubusercontent.com/youraverageazurecosplay-png/Minecrak/main/Minecrak.command \
        -o "$BASE_DIR/Minecrak.command"
      echo "$REMOTE_VERSION" > "$VERSION_FILE"
      echo "Updated. Restart Minecrak."
      exit 0
    fi
  fi
}

# =========================
# BACKUP SYSTEM
# =========================

backup_worlds() {
  DEST="$BACKUP_DIR/$(date +%Y-%m-%d_%H-%M-%S)"
  mkdir -p "$DEST"
  cp -r "$CORE_DIR/worlds" "$DEST/"
  echo "Worlds backed up to $DEST"
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
  read -rp "#? " choice
  case "$choice" in
    1) LOADER="fabric"; REPO="https://github.com/FabricMC/fabric-example-mod.git"; RUN_PATH="run" ;;
    2) LOADER="quilt"; REPO="https://github.com/QuiltMC/quilt-template-mod.git"; RUN_PATH="run" ;;
    3) LOADER="forge"; REPO="https://github.com/MinecraftForge/MinecraftForge.git"; RUN_PATH="run" ;;
    4) LOADER="neoforge"; REPO="https://github.com/NeoForgeMDKs/MDK-1.21.1-NeoGradle.git"; RUN_PATH="runs/client" ;;
    *) return 1 ;;
  esac
}

# =========================
# INSTANCE CREATION
# =========================

create_instance() {
  select_loader || return
  echo
  read -rp "Instance name: " NAME
  INSTANCE_DIR="$INSTANCES_DIR/$NAME"

  [ -d "$INSTANCE_DIR" ] && echo "Already exists." && pause && return

  git clone "$REPO" "$INSTANCE_DIR" || return

  read -rp "Username [Dev]: " USERNAME
  USERNAME="${USERNAME:-Dev}"

  read -rp "RAM (2G,4G,8G) [4G]: " RAM
  RAM="${RAM:-4G}"

  echo "$USERNAME" > "$INSTANCE_DIR/.username"

  cat > "$INSTANCE_DIR/.meta" <<EOF
LOADER=$LOADER
CREATED=$(date +%Y-%m-%d)
LAST_PLAYED=Never
MC_VERSION=1.21
RAM=$RAM
EOF

  mkdir -p "$INSTANCE_DIR/$RUN_PATH/mods"

  rm -rf "$INSTANCE_DIR/$RUN_PATH/saves"
  rm -rf "$INSTANCE_DIR/$RUN_PATH/config"

  ln -s "$CORE_DIR/worlds" "$INSTANCE_DIR/$RUN_PATH/saves"
  ln -s "$CORE_DIR/config/$LOADER" "$INSTANCE_DIR/$RUN_PATH/config"

  cat > "$INSTANCE_DIR/start.command" <<EOF
#!/usr/bin/env bash
cd "$INSTANCE_DIR"
USERNAME=\$(cat .username)
RAM=\$(grep RAM .meta | cut -d= -f2)
./gradlew runClient -Dorg.gradle.jvmargs="-Xmx\$RAM" --args="--username \$USERNAME"
EOF

  chmod +x "$INSTANCE_DIR/start.command"

  mkdir -p "$HOME/Desktop/Minecrak"
  ln -sf "$INSTANCE_DIR/start.command" "$HOME/Desktop/Minecrak/$NAME.command"

  echo "Instance created."
  pause
}

# =========================
# LIST INSTANCES
# =========================

list_instances() {
  echo
  for dir in "$INSTANCES_DIR"/*; do
    [ -d "$dir" ] || continue
    NAME=$(basename "$dir")
    source "$dir/.meta"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME"
    echo " Loader: $LOADER"
    echo " Created: $CREATED"
    echo " Last Played: $LAST_PLAYED"
    echo " RAM: $RAM"
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━"
  pause
}

# =========================
# LAUNCH INSTANCE
# =========================

launch_instance() {
  echo
  ls "$INSTANCES_DIR"
  echo
  read -rp "Launch: " NAME
  DIR="$INSTANCES_DIR/$NAME"
  [ ! -d "$DIR" ] && echo "Not found." && pause && return

  sed -i '' "s/LAST_PLAYED=.*/LAST_PLAYED=$(date +%Y-%m-%d)/" "$DIR/.meta" 2>/dev/null || true
  "$DIR/start.command"
  pause
}

# =========================
# DELETE INSTANCE
# =========================

delete_instance() {
  backup_worlds
  echo
  ls "$INSTANCES_DIR"
  read -rp "Delete: " NAME
  rm -rf "$INSTANCES_DIR/$NAME"
  rm -f "$HOME/Desktop/Minecrak/$NAME.command"
  echo "Deleted."
  pause
}

# =========================
# EXPORT / IMPORT
# =========================

export_instance() {
  ls "$INSTANCES_DIR"
  read -rp "Export which: " NAME
  tar -czf "$BASE_DIR/$NAME.tar.gz" -C "$INSTANCES_DIR" "$NAME"
  echo "Exported to $BASE_DIR/$NAME.tar.gz"
  pause
}

import_instance() {
  read -rp "Path to .tar.gz: " FILE
  tar -xzf "$FILE" -C "$INSTANCES_DIR"
  echo "Imported."
  pause
}

# =========================
# FULL UNINSTALL
# =========================

full_uninstall() {
  backup_worlds
  echo -e "${RED}Type DELETE to uninstall:${NC}"
  read confirm
  [ "$confirm" != "DELETE" ] && return

  rm -rf "$HOME/Desktop/Minecrak"
  rm -rf "$BASE_DIR"
  exit 0
}

# =========================
# MAIN MENU
# =========================

check_updates

while true; do
  clear
  echo -e "${GREEN}=== Minecrak v$VERSION ===${NC}"
  echo
  echo "1) Create Instance"
  echo "2) Launch Instance"
  echo "3) List Instances"
  echo "4) Delete Instance"
  echo "5) Export Instance"
  echo "6) Import Instance"
  echo "7) Full Uninstall"
  echo "8) Quit"
  echo
  read -rp "#? " opt

  case "$opt" in
    1) create_instance ;;
    2) launch_instance ;;
    3) list_instances ;;
    4) delete_instance ;;
    5) export_instance ;;
    6) import_instance ;;
    7) full_uninstall ;;
    8) exit 0 ;;
  esac
done
