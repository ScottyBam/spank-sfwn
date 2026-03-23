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


# Install SpankBar.app from pre-built zip
SPANKBAR_ZIP="$ROOT/dist/SpankBar.app.zip"
if [ -f "$SPANKBAR_ZIP" ]; then
    echo "Installing SpankBar.app..."
    unzip -o "$SPANKBAR_ZIP" -d /Applications/ >/dev/null
    echo "SpankBar.app installed to /Applications."

    # Install LaunchAgent for the real user (not root)
    AGENT_PLIST_SRC="$ROOT/SpankBar/com.scott-t-b.spankbar.plist"
    AGENT_PLIST_DEST="$USER_HOME/Library/LaunchAgents/com.scott-t-b.spankbar.plist"
    cp "$AGENT_PLIST_SRC" "$AGENT_PLIST_DEST"
    # Load as the real user
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" launchctl load "$AGENT_PLIST_DEST"
    else
        launchctl load "$AGENT_PLIST_DEST"
    fi
    echo "SpankBar LaunchAgent installed and loaded."
else
    echo "Warning: dist/SpankBar.app.zip not found — skipping SpankBar install."
fi

echo "Done. spank is running."
