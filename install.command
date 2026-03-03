#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Minecrak Installer =="
echo "Project folder: $SCRIPT_DIR"
echo "Instances folder: $SCRIPT_DIR/instances"

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

if [ -d "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
elif [ -d "/usr/local/opt/openjdk/libexec/openjdk.jdk" ]; then
  export JAVA_HOME="/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
fi

if [ -n "${JAVA_HOME:-}" ]; then
  echo "Using JAVA_HOME=$JAVA_HOME"
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
