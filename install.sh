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

mkdir -p "$INSTALL_DIR"

echo "Downloading Minecrak..."
curl -fsSL https://raw.githubusercontent.com/youraverageazurecosplay-png/Minecrak/main/Minecrak.command \
  -o "$INSTALL_DIR/Minecrak.command"

chmod +x "$INSTALL_DIR/Minecrak.command"

read -rp "Create Desktop shortcut? (y/n): " shortcut
if [[ "$shortcut" == "y" && -d "$HOME/Desktop" ]]; then
  ln -sf "$INSTALL_DIR/Minecrak.command" "$HOME/Desktop/Minecrak.command"
fi

echo
echo "✅ Installed successfully!"
echo "Location: $INSTALL_DIR"
echo
echo "Run with:"
echo "$INSTALL_DIR/Minecrak.command"
