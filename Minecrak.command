full_uninstall() {
  echo
  echo "⚠️  FULL UNINSTALL"
  echo
  echo "This will permanently delete:"
  echo "$BASE_DIR"
  echo
  echo "This includes:"
  echo "- All instances"
  echo "- All worlds"
  echo "- All shared config"
  echo "- All mods"
  echo
  read -rp "Type DELETE to confirm: " confirm

  if [ "$confirm" != "DELETE" ]; then
    echo "Cancelled."
    pause
    return
  fi

  echo
  echo "Removing Desktop shortcut (if exists)..."
  rm -f "$HOME/Desktop/Minecrak.command" 2>/dev/null || true

  echo "Deleting Minecrak directory..."
  rm -rf "$BASE_DIR"

  echo
  echo "Minecrak fully removed."
  exit 0
}
