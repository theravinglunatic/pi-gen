#!/bin/bash -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Disabling User Configuration Wizard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# The Raspberry Pi OS userconf wizard runs on first boot if no user is detected
# This interferes with our pre-configured 'noface' user
# We disable it by creating a marker file and removing the service

echo "📝 Disabling userconf-pi (userconfig) service..."
on_chroot << EOF
# Mask the correct user configuration service to prevent any wizard
systemctl disable userconfig.service 2>/dev/null || true
systemctl mask userconfig.service 2>/dev/null || true
EOF

# Clean any autologin trigger that would start the wizard user session
echo "🧹 Removing userconf autologin trigger if present..."
rm -f "${ROOTFS_DIR}/var/lib/userconf-pi/autologin" || true

# Ensure the service is not pulled in by multi-user target
echo "🧹 Removing userconfig wants symlink if present..."
rm -f "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/userconfig.service" || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ User Configuration Wizard Disabled"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "User 'noface' is pre-configured, wizard will not run."
echo ""
