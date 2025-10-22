#!/bin/bash -e

# This runs at the very end of the export-image stage
# Display important flashing instructions

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║  ⚠️  CRITICAL: DO NOT USE RASPBERRY PI IMAGER TO FLASH THIS IMAGE       ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 RASPBERRY PI IMAGER WILL BREAK THIS IMAGE!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This image uses CUSTOM FIRST-BOOT AUTOMATION via USB deploy key.

Raspberry Pi Imager adds cloud-init files that will:
  ❌ Override your custom first-boot service
  ❌ Break USB-based deployment key system
  ❌ Prevent repository cloning automation
  ❌ Cause setup to fail completely

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CORRECT FLASHING METHODS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Method 1: dd (handles .xz compression automatically)
  lsblk  # Find your SD card device
  sudo dd if=deploy/image_*.img.xz of=/dev/sdX bs=4M status=progress conv=fsync

Method 2: bmaptool (faster, uses block map)
  lsblk  # Find your SD card device
  sudo bmaptool copy deploy/image_*.img.xz /dev/sdX

Method 3: Uncompress first, then use any tool
  unxz deploy/image_*.img.xz
  # Now you can use Balena Etcher, Win32DiskImager, etc. with the .img file

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DEPLOYMENT CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before booting:

[ ] Prepare USB drive:
    mkdir -p /media/usb/.deploy
    mkdir -p /media/usb/Videos
    cp ~/.ssh/id_ed25519 /media/usb/.deploy/deploy_key
    chmod 600 /media/usb/.deploy/deploy_key
    # Add video files to Videos/

[ ] Flash SD card with dd or bmaptool (NOT Raspberry Pi Imager)

[ ] Insert SD card into Pi 5

[ ] Insert prepared USB drive

[ ] Connect ethernet cables (eth0 production, eth1 internet)

[ ] Power on and wait 3-5 minutes for first-boot automation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cloud-init has been DISABLED in this image.
Custom first-boot service will handle all automation.

See: stage2/05-disable-cloud-init/README.md for details

EOF

