#!/bin/bash -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚫 Disabling Cloud-Init for Custom First-Boot"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Cloud-init interferes with our custom faceless-first-boot.service
# Raspberry Pi Imager adds cloud-init files that override our automation
# We completely disable it to ensure our USB-based deployment works

# Create cloud-init disable marker (most reliable method)
echo "📝 Creating cloud-init disable marker..."
install -d "${ROOTFS_DIR}/etc/cloud"
touch "${ROOTFS_DIR}/etc/cloud/cloud-init.disabled"

# Mask all cloud-init services to prevent activation
echo "🔒 Masking cloud-init systemd services..."
on_chroot << EOF
systemctl mask cloud-init-local.service 2>/dev/null || true
systemctl mask cloud-init.service 2>/dev/null || true
systemctl mask cloud-config.service 2>/dev/null || true
systemctl mask cloud-final.service 2>/dev/null || true
EOF

# Remove cloud-init package entirely (cleanest approach)
echo "🗑️  Removing cloud-init package..."
on_chroot << EOF
# Remove cloud-init and its dependencies
DEBIAN_FRONTEND=noninteractive apt-get remove -y cloud-init 2>/dev/null || true
apt-get autoremove -y
apt-get clean
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Cloud-Init Disabled Successfully"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "System will use custom faceless-first-boot.service instead."
echo "This prevents Raspberry Pi Imager from interfering with setup."
echo ""
echo "⚠️  IMPORTANT: Flash with dd or bmaptool, NOT Raspberry Pi Imager"
echo "   sudo dd if=deploy/image_*.img.xz of=/dev/sdX bs=4M status=progress"
echo ""

