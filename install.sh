#!/usr/bin/env bash
set -e

echo "=== Minecrak Installer ==="
echo

read -rp "Install location [$HOME]: " INSTALL_BASE
INSTALL_BASE="${INSTALL_BASE:-$HOME}"

INSTALL_DIR="$INSTALL_BASE/Minecrak"

if [ -d "$INSTALL_DIR" ]; then
  echo
  read -rp "Minecrak already exists. Reinstall? (y/n): " ans
  if [[ "$ans" != "y" ]]; then
    exit 1
  fi
  rm -rf "$INSTALL_DIR"
fi

echo
echo "Creating Minecrak directory..."
mkdir -p "$INSTALL_DIR"

echo "Downloading Minecrak Control Panel..."
curl -fsSL https://raw.githubusercontent.com/youraverageazurecosplay-png/Minecrak/main/Minecrak.command \
  -o "$INSTALL_DIR/Minecrak.command"

chmod +x "$INSTALL_DIR/Minecrak.command"

echo
echo "Creating Desktop Minecrak folder..."

DESKTOP_FOLDER="$HOME/Desktop/Minecrak"
mkdir -p "$DESKTOP_FOLDER"

ln -sf "$INSTALL_DIR/Minecrak.command" \
       "$DESKTOP_FOLDER/Minecrak Control Panel.command"

echo
echo "✅ Minecrak installed successfully!"
echo
echo "Open from:"
echo "$DESKTOP_FOLDER/Minecrak Control Panel.command"
echo
