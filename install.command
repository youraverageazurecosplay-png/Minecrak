#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Minecrak Installer =="
echo "Project folder: $SCRIPT_DIR"
echo "Instances folder: $SCRIPT_DIR/instances"

ask_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  local answer
  if [ "$default" = "Y" ]; then
    read -r "?$prompt [Y/n]: " answer
    answer="${answer:-Y}"
  else
    read -r "?$prompt [y/N]: " answer
    answer="${answer:-N}"
  fi
  case "$answer" in
    Y|y|Yes|yes) return 0 ;;
    *) return 1 ;;
  esac
}

if ask_yes_no "Install/ensure required packages with Homebrew (git, python, openjdk)?" "Y"; then
  if ! command -v xcode-select >/dev/null 2>&1; then
    echo "xcode-select not found. Install Xcode Command Line Tools and re-run."
    exit 1
  fi

  if ! xcode-select -p >/dev/null 2>&1; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    echo "Complete the Xcode tools installation, then run install.command again."
    exit 1
  fi

  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is not installed."
    echo "Install Homebrew from https://brew.sh and re-run this installer."
    exit 1
  fi

  echo "Installing required packages (git, python, openjdk)..."
  brew install git python openjdk
else
  echo "Skipping package installation."
fi

if [ -d "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
elif [ -d "/usr/local/opt/openjdk/libexec/openjdk.jdk" ]; then
  export JAVA_HOME="/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
fi

if [ -n "${JAVA_HOME:-}" ]; then
  echo "Using JAVA_HOME=$JAVA_HOME"
fi

echo "Checking required commands..."
missing=0
for cmd in git python3 java; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing: $cmd"
    missing=1
  fi
done
if [ "$missing" -ne 0 ]; then
  echo "One or more required commands are missing."
  echo "Re-run installer and choose package installation, or install dependencies manually."
fi

echo "Creating runtime folders..."
mkdir -p "$SCRIPT_DIR/instances"

cat > "$SCRIPT_DIR/start.command" <<'LAUNCHER'
#!/bin/zsh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
exec python3 "$SCRIPT_DIR/main.py"
LAUNCHER
chmod +x "$SCRIPT_DIR/start.command"

chmod +x "$SCRIPT_DIR/main.py"

echo "Installer finished."
echo "Run with: $SCRIPT_DIR/start.command"
echo "Main folder: $SCRIPT_DIR"
echo "Instances folder: $SCRIPT_DIR/instances"
