#!/usr/bin/env bash
set -e

echo "=== Minecrak Installer ==="
echo

read -rp "Install location [$HOME]: " INSTALL_BASE
INSTALL_BASE="${INSTALL_BASE:-$HOME}"

INSTALL_DIR="$INSTALL_BASE/Minecrak"

if [ -d "$INSTALL_DIR" ]; then
  echo "Minecrak already installed at:"
  echo "$INSTALL_DIR"
  exit 1
fi

echo
echo "Creating directory..."
mkdir -p "$INSTALL_DIR"

echo "Downloading Minecrak Manager..."
curl -fsSL https://raw.githubusercontent.com/youraverageazurecosplay-png/Minecrak/main/Minecrak.command \
  -o "$INSTALL_DIR/Minecrak.command"

chmod +x "$INSTALL_DIR/Minecrak.command"

echo
read -rp "Create Desktop shortcut? (y/n): " shortcut
if [[ "$shortcut" == "y" && -d "$HOME/Desktop" ]]; then
  ln -s "$INSTALL_DIR/Minecrak.command" "$HOME/Desktop/Minecrak.command"
fi

echo
echo "✅ Minecrak installed!"
echo "Location: $INSTALL_DIR"
echo
echo "Run it with:"
echo "$INSTALL_DIR/Minecrak.command"
