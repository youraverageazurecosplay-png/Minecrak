#!/bin/zsh
set -eo pipefail

REPO_URL="https://github.com/youraverageazurecosplay-png/Minecrak.git"
TARGET_DIR="$HOME/Minecrak"
DRY_RUN="${DRY_RUN:-0}"

# Launcher-specific high-contrast colors (avoid collisions with user shell vars).
MCRK_GREEN="\033[1;92m"
MCRK_YELLOW="\033[1;93m"
MCRK_RED="\033[1;91m"
MCRK_RESET="\033[0m"

say() {
  printf "%b%s%b\n" "$1" "$2" "$MCRK_RESET"
}

say "$MCRK_GREEN" "== Minecrak Bootstrap =="
echo "Repository: $REPO_URL"
echo "Install path: $TARGET_DIR"

if [ "$DRY_RUN" = "1" ]; then
  say "$MCRK_YELLOW" "DRY_RUN enabled: skipping clone/pull/install/launch actions."
  exit 0
fi

if [ -d "$TARGET_DIR/.git" ]; then
  say "$MCRK_YELLOW" "Existing installation found. Pulling latest changes..."
  git -C "$TARGET_DIR" pull --ff-only
elif [ -d "$TARGET_DIR" ]; then
  say "$MCRK_RED" "Folder exists but is not a git repository: $TARGET_DIR"
  echo "Move/delete it, or set a different target path in Minecrak.command."
  exit 1
else
  say "$MCRK_YELLOW" "Cloning repository..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
chmod +x install.command start.command main.py

say "$MCRK_YELLOW" "Running installer..."
./install.command

read -r "?Launch Minecrak now? [Y/n]: " launch_now
launch_now="${launch_now:-Y}"
case "$launch_now" in
  Y|y|Yes|yes) ./start.command ;;
  *) say "$MCRK_GREEN" "You can launch anytime with: $TARGET_DIR/start.command" ;;
esac
