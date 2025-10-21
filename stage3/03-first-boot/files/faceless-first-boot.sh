#!/bin/bash
# FacelessWebServer First Boot Automated Setup
# Loads deploy key from USB drive and configures the application

set -e

# Configuration
REPO_URL="git@github.com:theravinglunatic/facelessWebServer.git"
APP_DIR="/home/noface/facelessWebServer"
COMPLETION_MARKER="/var/lib/faceless-first-boot-done"
LOG_FILE="/var/log/faceless-first-boot.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🚀 FacelessWebServer First Boot Setup Starting"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit if already completed
if [ -f "$COMPLETION_MARKER" ]; then
    log "✓ Setup already completed. Skipping."
    exit 0
fi

# Wait for USB drive to be mounted
log "📀 Waiting for USB drive..."
USB_MOUNT=""
MAX_WAIT=120
WAITED=0

# Check common mount points
while [ $WAITED -lt $MAX_WAIT ]; do
    # Check udisks2 automount locations
    for MOUNT in /media/noface/*; do
        if [ -d "$MOUNT" ]; then
            USB_MOUNT="$MOUNT"
            break
        fi
    done
    
    # Check traditional mount points
    if [ -z "$USB_MOUNT" ]; then
        for MOUNT in /media/usb0 /media/usb /mnt/usb; do
            if [ -d "$MOUNT" ] && mountpoint -q "$MOUNT" 2>/dev/null; then
                USB_MOUNT="$MOUNT"
                break
            fi
        done
    fi
    
    # Exit loop if found
    if [ -n "$USB_MOUNT" ] && [ -d "$USB_MOUNT/Videos" ]; then
        log "✓ USB drive found at: $USB_MOUNT"
        break
    fi
    
    sleep 2
    WAITED=$((WAITED + 2))
    USB_MOUNT=""
done

if [ -z "$USB_MOUNT" ]; then
    log "❌ ERROR: USB drive not found after ${MAX_WAIT}s"
    log ""
    log "Expected USB structure:"
    log "  /media/noface/<UUID>/"
    log "  ├── Videos/              (video content)"
    log "  └── .deploy/"
    log "      └── deploy_key       (SSH private key)"
    log ""
    log "Please:"
    log "  1. Insert USB drive with Videos/ directory"
    log "  2. Create .deploy/deploy_key on the USB drive"
    log "  3. Reboot or run: sudo systemctl start faceless-first-boot.service"
    exit 1
fi

# Check for deploy key on USB
USB_KEY="$USB_MOUNT/.deploy/deploy_key"
if [ ! -f "$USB_KEY" ]; then
    log "❌ ERROR: Personal SSH key not found at $USB_KEY"
    log ""
    log "To add your personal SSH key to USB:"
    log "  1. On your dev machine, copy your key:"
    log "     mkdir -p /path/to/usb/.deploy"
    log "     cp ~/.ssh/id_ed25519 /path/to/usb/.deploy/deploy_key"
    log "     chmod 600 /path/to/usb/.deploy/deploy_key"
    log "  2. Reboot or run: sudo systemctl start faceless-first-boot.service"
    log ""
    log "Note: Using personal SSH key provides full read/write access"
    log "      for development work. This is a development image."
    exit 1
fi

log "✓ Personal SSH key found on USB drive"

# Verify SSH key permissions on USB
ACTUAL_PERMS=$(stat -c "%a" "$USB_KEY")
if [ "$ACTUAL_PERMS" != "600" ] && [ "$ACTUAL_PERMS" != "400" ]; then
    log "⚠️  Warning: SSH key permissions are $ACTUAL_PERMS (expected 600)"
    log "   Fixing permissions..."
    chmod 600 "$USB_KEY"
fi

# Setup SSH directory for noface user
log "🔑 Configuring SSH for user noface..."
mkdir -p /home/noface/.ssh
chmod 700 /home/noface/.ssh
chown noface:noface /home/noface/.ssh

# Copy personal SSH key from USB to home directory (for full git access)
cp "$USB_KEY" /home/noface/.ssh/id_ed25519
chmod 600 /home/noface/.ssh/id_ed25519
chown noface:noface /home/noface/.ssh/id_ed25519
log "✓ Personal SSH key copied to /home/noface/.ssh/id_ed25519"

# Configure SSH for GitHub (standard config, uses default key)
cat > /home/noface/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF
chmod 600 /home/noface/.ssh/config
chown noface:noface /home/noface/.ssh/config
log "✓ SSH config created"

# Add GitHub to known_hosts
sudo -u noface ssh-keyscan github.com >> /home/noface/.ssh/known_hosts 2>/dev/null || true
log "✓ GitHub added to known_hosts"

# Test SSH connection to GitHub
log "🔍 Testing GitHub SSH connection..."
if sudo -u noface ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log "✓ GitHub SSH authentication successful"
else
    log "⚠️  Warning: GitHub SSH test failed"
    log "   Proceeding with clone attempt..."
fi

# Clone repository
log "📥 Cloning FacelessWebServer repository..."
if [ -d "$APP_DIR" ]; then
    log "⚠️  Application directory already exists at $APP_DIR"
    log "   Updating repository..."
    cd "$APP_DIR"
    sudo -u noface git pull origin main || sudo -u noface git pull origin master || log "⚠️  Git pull failed, continuing..."
else
    sudo -u noface git clone "$REPO_URL" "$APP_DIR" || {
        log "❌ ERROR: Failed to clone repository"
        log "   Check that:"
        log "   1. Personal SSH key on USB is correct"
        log "   2. SSH key has access to GitHub account"
        log "   3. Repository URL is correct: $REPO_URL"
        exit 1
    }
    log "✓ Repository cloned successfully"
fi

cd "$APP_DIR"

# Install Python dependencies
log "🐍 Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --break-system-packages 2>&1 | tee -a "$LOG_FILE" || \
    pip3 install -r requirements.txt 2>&1 | tee -a "$LOG_FILE" || \
    log "⚠️  Some Python packages may have failed to install"
    log "✓ Python dependencies installed"
else
    log "⚠️  No requirements.txt found, installing essential packages..."
    pip3 install --break-system-packages python-mpv websockets pillow gpiozero lgpio psutil 2>&1 | tee -a "$LOG_FILE" || \
    pip3 install python-mpv websockets pillow gpiozero lgpio psutil 2>&1 | tee -a "$LOG_FILE"
fi

# Install Node.js dependencies
log "📦 Installing Node.js dependencies..."
if [ -d "no_face_remote_client" ]; then
    cd "$APP_DIR/no_face_remote_client"
    if [ -f "package.json" ]; then
        sudo -u noface npm install 2>&1 | tee -a "$LOG_FILE"
        log "✓ Node.js dependencies installed"
    else
        log "⚠️  No package.json found in no_face_remote_client/"
    fi
else
    log "⚠️  no_face_remote_client directory not found"
fi

# Install VCR EAS font if available
log "🔤 Installing VCR EAS font..."
FONT_SOURCE="$APP_DIR/no_face_core/fonts/VcrEas-rX3K.ttf"
FONT_DEST="/usr/local/share/fonts/truetype/noface"
if [ -f "$FONT_SOURCE" ]; then
    mkdir -p "$FONT_DEST"
    cp "$FONT_SOURCE" "$FONT_DEST/"
    chmod 644 "$FONT_DEST/VcrEas-rX3K.ttf"
    fc-cache -fv 2>&1 | tee -a "$LOG_FILE"
    log "✓ VCR EAS font installed"
else
    log "⚠️  Font file not found at $FONT_SOURCE (will be installed manually if needed)"
fi

# Set correct permissions
log "🔒 Setting application permissions..."
chown -R noface:noface "$APP_DIR"
chmod -R 755 "$APP_DIR"
log "✓ Permissions set"

# Enable and start the service
log "⚙️  Enabling no_face_core service..."
systemctl enable no_face_core.service
systemctl start no_face_core.service
log "✓ Service enabled and started"

# Mark setup as complete
touch "$COMPLETION_MARKER"
log "✓ Setup completion marker created"

# Display service status
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✅ FacelessWebServer Setup Complete!"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""
log "Service Status:"
systemctl status no_face_core.service --no-pager | tee -a "$LOG_FILE" || true
log ""
log "📍 Application installed at: $APP_DIR"
log "📀 USB drive mounted at: $USB_MOUNT"
log "📝 Setup log: $LOG_FILE"
log ""
log "To view logs:"
log "  journalctl -u no_face_core.service -f"
log ""
log "To view this boot log:"
log "  cat $LOG_FILE"
log ""

exit 0
