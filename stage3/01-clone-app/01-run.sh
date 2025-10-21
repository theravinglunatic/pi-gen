#!/bin/bash -e

# Install the first-boot setup script
install -v -m 755 files/setup-faceless.sh "${ROOTFS_DIR}/usr/local/bin/setup-faceless.sh"

# Create instructions file for user
cat > "${ROOTFS_DIR}/home/noface/SETUP_INSTRUCTIONS.txt" << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 FacelessWebServer Setup Instructions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This image is pre-configured with all system dependencies for
FacelessWebServer. However, the application repository is private
and must be installed after first boot.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 SETUP STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣  Generate SSH Deploy Key
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''

2️⃣  Add Public Key to GitHub
   cat ~/.ssh/id_ed25519.pub
   
   Go to: https://github.com/theravinglunatic/facelessWebServer/settings/keys
   Add deploy key with READ-ONLY access

3️⃣  Run Setup Script
   sudo /usr/local/bin/setup-faceless.sh

4️⃣  Verify Service
   systemctl status no_face_core

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 ALTERNATIVE: Manual Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If you prefer manual setup or have credentials configured:

git clone git@github.com:theravinglunatic/facelessWebServer.git
cd facelessWebServer

# Install Python dependencies
pip3 install python-mpv websockets pillow gpiozero lgpio psutil

# Install Node.js dependencies
cd no_face_remote_client
npm install

# Enable service
sudo systemctl enable --now no_face_core.service

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ WHAT'S ALREADY CONFIGURED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ User: noface (SSH key-only authentication)
✓ Hostname: noface.local
✓ Network: Dual ethernet (eth0: 192.168.8.2, eth1: DHCP)
✓ Packages: mpv, NetworkManager, Python, Node.js, GPIO libraries
✓ Services: NetworkManager, avahi-daemon, udisks2
✓ SystemD: no_face_core.service template created
✓ Disabled: dhcpcd, dnsmasq (prevent conflicts)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Check network:
  ip route show
  # Should show default via eth1 only

Check services:
  systemctl status NetworkManager
  systemctl status no_face_core

View logs:
  journalctl -u no_face_core -f

Test mDNS:
  avahi-browse -at | grep noface

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For more information, see:
  /home/noface/.github/DEPLOYMENT.md (after app is cloned)

EOF

chown 1000:1000 "${ROOTFS_DIR}/home/noface/SETUP_INSTRUCTIONS.txt"
chmod 644 "${ROOTFS_DIR}/home/noface/SETUP_INSTRUCTIONS.txt"
