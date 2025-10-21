#!/bin/bash -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Configuring FacelessWebServer System Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install NetworkManager connection profiles
echo "📡 Installing NetworkManager connection profiles..."
install -v -m 600 -o root -g root files/Production-eth0.nmconnection \
    "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Production-eth0.nmconnection"
install -v -m 600 -o root -g root files/Development-eth1.nmconnection \
    "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Development-eth1.nmconnection"

# Install systemd service
echo "⚙️  Installing systemd service..."
install -v -m 644 files/no_face_core.service \
    "${ROOTFS_DIR}/etc/systemd/system/no_face_core.service"

# Disable conflicting services
echo "🚫 Disabling conflicting services..."
on_chroot << EOF
# Disable dhcpcd (conflicts with NetworkManager)
systemctl disable dhcpcd || true
systemctl mask dhcpcd || true

# Disable dnsmasq (conflicts with NetworkManager)
systemctl disable dnsmasq || true
systemctl mask dnsmasq || true

# Disable hostapd (not needed for this setup)
systemctl disable hostapd || true
systemctl mask hostapd || true

# Disable bluetooth (optional, saves resources)
systemctl disable bluetooth || true
EOF

# Enable required services
echo "✅ Enabling required services..."
on_chroot << EOF
# Enable NetworkManager
systemctl enable NetworkManager
systemctl enable NetworkManager-wait-online

# Enable mDNS/Avahi
systemctl enable avahi-daemon

# Enable USB automount
systemctl enable udisks2

# Note: no_face_core.service will be enabled by setup script
# after repository is cloned
EOF

# Create application directory placeholder
echo "📁 Creating application directory..."
mkdir -p "${ROOTFS_DIR}/home/noface/facelessWebServer"
chown 1000:1000 "${ROOTFS_DIR}/home/noface/facelessWebServer"

# Configure Python pip for system-wide installs (no venv needed)
echo "🐍 Configuring Python pip..."
mkdir -p "${ROOTFS_DIR}/home/noface/.config/pip"
cat > "${ROOTFS_DIR}/home/noface/.config/pip/pip.conf" << 'PIPCONF'
[global]
break-system-packages = true
PIPCONF
chown -R 1000:1000 "${ROOTFS_DIR}/home/noface/.config"

# Create .ssh directory with proper permissions
echo "🔑 Preparing SSH directory..."
mkdir -p "${ROOTFS_DIR}/home/noface/.ssh"
chown 1000:1000 "${ROOTFS_DIR}/home/noface/.ssh"
chmod 700 "${ROOTFS_DIR}/home/noface/.ssh"

# Add GitHub to known_hosts
on_chroot << EOF
sudo -u noface ssh-keyscan github.com >> /home/noface/.ssh/known_hosts 2>/dev/null || true
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ System Configuration Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configured services:"
echo "  ✓ NetworkManager (dual ethernet)"
echo "  ✓ Avahi daemon (mDNS)"
echo "  ✓ udisks2 (USB automount)"
echo "  ✓ no_face_core.service (template installed)"
echo ""
echo "Disabled services:"
echo "  ✗ dhcpcd (conflicts with NetworkManager)"
echo "  ✗ dnsmasq (conflicts with NetworkManager)"
echo "  ✗ hostapd (not needed)"
echo "  ✗ bluetooth (optional)"
echo ""
