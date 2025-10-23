#!/bin/bash -e

# First-boot setup script for FacelessWebServer
# This script clones the private repository using SSH deploy key
# and installs all application dependencies.

REPO_URL="git@github.com:theravinglunatic/facelessWebServer.git"
INSTALL_DIR="/home/noface/facelessWebServer"
SETUP_MARKER="/home/noface/.faceless_setup_complete"

# Exit if already set up
if [ -f "$SETUP_MARKER" ]; then
    echo "Setup already completed. Skipping."
    exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 FacelessWebServer First-Boot Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if SSH key exists
if [ ! -f /home/noface/.ssh/id_ed25519 ]; then
    echo "❌ ERROR: SSH deploy key not found!"
    echo ""
    echo "Please add deploy key to /home/noface/.ssh/id_ed25519"
    echo "Instructions:"
    echo "  1. Generate key: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''"
    echo "  2. Add public key to GitHub deploy keys"
    echo "  3. Run this script again: sudo /usr/local/bin/setup-faceless.sh"
    exit 1
fi

# Ensure repository is present and cleanly synced to origin/HEAD
echo "📥 Preparing FacelessWebServer repository..."
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "   Existing git repository detected; syncing to origin HEAD..."
    sudo -u noface bash -lc "set -e; cd '$INSTALL_DIR'; git remote set-url origin '$REPO_URL' || true; git fetch origin --prune; HEAD_BRANCH=\$(git remote show origin | awk '/HEAD branch/ {print \$NF}'); git reset --hard \"origin/\${HEAD_BRANCH:-main}\"; git submodule update --init --recursive || true"
else
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️  $INSTALL_DIR exists but is not a git repo; moving aside and cloning fresh..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)" || true
    fi
    sudo -u noface git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Install Python dependencies (system-wide, no venv)
echo "🐍 Installing Python dependencies..."
pip3 install --break-system-packages python-mpv websockets pillow gpiozero lgpio psutil || \
    pip3 install python-mpv websockets pillow gpiozero lgpio psutil

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
if [ -d "$INSTALL_DIR/no_face_remote_client" ] && [ -f "$INSTALL_DIR/no_face_remote_client/package.json" ]; then
    cd "$INSTALL_DIR/no_face_remote_client"
    sudo -u noface npm ci || sudo -u noface npm install
else
    echo "⚠️  no_face_remote_client directory or package.json not found; skipping Node install"
fi

# Install VCR EAS font
echo "🔤 Installing VCR EAS font..."
if [ -f "$INSTALL_DIR/no_face_core/fonts/VcrEas-rX3K.ttf" ]; then
    mkdir -p /usr/local/share/fonts/truetype/noface
    cp "$INSTALL_DIR/no_face_core/fonts/VcrEas-rX3K.ttf" \
       /usr/local/share/fonts/truetype/noface/
    chmod 644 /usr/local/share/fonts/truetype/noface/VcrEas-rX3K.ttf
    fc-cache -fv
    echo "✓ Font installed"
else
    echo "⚠️  Font file not found, skipping"
fi

# Set permissions
echo "🔒 Setting permissions..."
chown -R noface:noface "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

# Enable and start service
echo "⚙️  Enabling no_face_core service..."
systemctl enable no_face_core.service
systemctl start no_face_core.service

# Mark setup as complete
touch "$SETUP_MARKER"
chown noface:noface "$SETUP_MARKER"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Service status: systemctl status no_face_core"
echo "View logs: journalctl -u no_face_core -f"
echo ""
