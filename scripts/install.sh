#!/bin/bash
# spank-sfwn install script
# Usage: sudo bash scripts/install.sh
# Installs spank + spank-supervisor, loads the LaunchDaemon.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

# Resolve the real user's home dir (works even when called via sudo)
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

INSTALL_DIR="/usr/local/bin"
DAEMON_PLIST_SRC="$ROOT/LaunchDaemons/com.taigrr.spank.plist"
DAEMON_PLIST_DEST="/Library/LaunchDaemons/com.taigrr.spank.plist"
DAEMON_LABEL="com.taigrr.spank"

echo "Installing spank-sfwn for user home: $USER_HOME"

# Build
echo "Building..."
cd "$ROOT"
go build -o spank .
go build -o spank-supervisor ./supervisor/

# Install binaries
mkdir -p "$INSTALL_DIR"
cp spank "$INSTALL_DIR/spank"
cp spank-supervisor "$INSTALL_DIR/spank-supervisor"
codesign --force --deep --sign - "$INSTALL_DIR/spank"
codesign --force --deep --sign - "$INSTALL_DIR/spank-supervisor"
echo "Binaries installed."

# Install LaunchDaemon plist
cp "$DAEMON_PLIST_SRC" "$DAEMON_PLIST_DEST"
sed -i '' "s|__SPANK_USER_HOME__|$USER_HOME|g" "$DAEMON_PLIST_DEST"
chown root:wheel "$DAEMON_PLIST_DEST"
chmod 644 "$DAEMON_PLIST_DEST"
echo "Plist installed: $DAEMON_PLIST_DEST (SPANK_USER_HOME=$USER_HOME)"

# Load or reload daemon
if launchctl print "system/$DAEMON_LABEL" >/dev/null 2>&1; then
    launchctl kickstart -k "system/$DAEMON_LABEL"
    echo "Daemon restarted."
else
    launchctl bootstrap system "$DAEMON_PLIST_DEST"
    echo "Daemon loaded."
fi

echo "Done. spank is running."
