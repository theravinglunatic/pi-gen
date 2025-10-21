#!/bin/bash -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Installing First-Boot Setup Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install first-boot setup script
install -v -m 755 files/faceless-first-boot.sh "${ROOTFS_DIR}/usr/local/bin/faceless-first-boot.sh"

# Install systemd service
install -v -m 644 files/faceless-first-boot.service "${ROOTFS_DIR}/etc/systemd/system/faceless-first-boot.service"

# Enable the service
on_chroot << EOF
systemctl enable faceless-first-boot.service
EOF

# Create USB drive preparation instructions
cat > "${ROOTFS_DIR}/home/noface/USB_SETUP_INSTRUCTIONS.txt" << 'EOFUSB'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 USB Drive Setup Instructions for FacelessWebServer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This image uses AUTOMATED first-boot setup via USB personal SSH key.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 REQUIRED USB DRIVE STRUCTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your USB drive must have:

/media/noface/<UUID>/
├── Videos/                      # Video content (required by app)
│   ├── video1.mp4
│   ├── video2.mp4
│   └── ...
├── staticVideos/                # 50% probability selection
├── interrupterVideo/            # EAS background video
├── interrupterImage/            # Generated overlay images
└── .deploy/                     # Deploy key directory (HIDDEN)
    └── deploy_key               # Your personal SSH key (chmod 600)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 PREPARING YOUR PERSONAL SSH KEY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is a DEVELOPMENT/TRANSITION image. Use your personal SSH key for
full read/write access to the repository.

1️⃣  Prepare USB Drive with Personal SSH Key:

    # Mount your USB drive
    USB_PATH="/path/to/your/usb/drive"

    # Create hidden deploy directory
    mkdir -p "$USB_PATH/.deploy"

    # Copy YOUR PERSONAL SSH key to USB
    cp ~/.ssh/id_ed25519 "$USB_PATH/.deploy/deploy_key"

    # Set correct permissions (CRITICAL!)
    chmod 600 "$USB_PATH/.deploy/deploy_key"

    # Verify structure
    ls -la "$USB_PATH/.deploy/"
    # Should show: -rw------- deploy_key

Note: Your personal SSH key provides full git access (clone, pull, push)
      for remote development via VS Code. This is appropriate for a
      development image, not production deployment.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 DEPLOYMENT WORKFLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Flash this image to SD card
2. Insert prepared USB drive (with .deploy/deploy_key)
3. Insert SD card into Raspberry Pi 5
4. Connect ethernet cables:
   - eth0 → GL.iNet router (production network)
   - eth1 → Home router (internet access)
5. Power on

AUTOMATIC FIRST-BOOT PROCESS:
  ⏱️  Boot → Wait for USB drive (up to 2 minutes)
  🔑 Load personal SSH key from USB
  📥 Clone repository from GitHub (git@github.com:theravinglunatic/facelessWebServer.git)
  🐍 Install Python dependencies
  📦 Install Node.js dependencies
  🔤 Install fonts
  ⚙️  Enable and start service
  ✅ Complete!

Total time: ~3-5 minutes (depending on internet speed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After first boot completes, SSH in and check:

ssh noface@noface.local

# Check first-boot log
cat /var/log/faceless-first-boot.log

# Check service status
systemctl status no_face_core.service

# View service logs
journalctl -u no_face_core.service -f

# Test web interface
curl http://localhost

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If first-boot fails:

1. Check USB drive is properly mounted:
   ls /media/noface/*/Videos/

2. Check deploy key exists on USB:
   ls -la /media/noface/*/.deploy/deploy_key

3. Verify your personal SSH key has GitHub access:
   ssh -T git@github.com

4. Check first-boot log for errors:
   cat /var/log/faceless-first-boot.log

5. Manually retry first-boot:
   sudo systemctl start faceless-first-boot.service
   journalctl -u faceless-first-boot.service -f

6. Check service logs:
   journalctl -u no_face_core.service -n 50

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 SECURITY NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Personal SSH key stored ONLY on your USB drive (not in image)
✓ Private key never exposed in public pi-gen repository
✓ Full read/write access for development (git push/pull works)
✓ USB drive is physically secured (you control it)
✓ Enables VS Code remote development workflow

⚠️  Keep your USB drive secure!
⚠️  Keep a backup of your SSH key in a safe location
⚠️  This is a DEVELOPMENT image - use deploy keys for production

💻 REMOTE DEVELOPMENT:
   VS Code Remote SSH works perfectly with this setup:
   - Connect to: noface@noface.local
   - Full git access (push, pull, fetch)
   - Edit files remotely
   - Run/debug directly on Pi

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOFUSB

chown 1000:1000 "${ROOTFS_DIR}/home/noface/USB_SETUP_INSTRUCTIONS.txt"
chmod 644 "${ROOTFS_DIR}/home/noface/USB_SETUP_INSTRUCTIONS.txt"

echo ""
echo "✅ First-Boot Setup Service Installed"
echo ""
echo "Configuration:"
echo "  ✓ faceless-first-boot.service (enabled)"
echo "  ✓ /usr/local/bin/faceless-first-boot.sh"
echo "  ✓ ~/USB_SETUP_INSTRUCTIONS.txt (for user)"
echo ""
echo "First boot will:"
echo "  1. Wait for USB drive (up to 2 minutes)"
echo "  2. Load deploy key from USB://.deploy/deploy_key"
echo "  3. Clone repository via SSH"
echo "  4. Install dependencies"
echo "  5. Start service"
echo ""
