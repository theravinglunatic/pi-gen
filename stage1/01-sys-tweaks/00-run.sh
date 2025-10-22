#!/bin/bash -e

install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

# Set WiFi country code to suppress raspi-config warning (even though using ethernet only)
# Using US since your timezone is America/New_York
echo "Setting WiFi country code to US..."
on_chroot << EOF
raspi-config nonint do_wifi_country US
EOF

on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi

if [ -n "${FIRST_USER_PASS}" ]; then
	echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
fi
echo "root:root" | chpasswd
EOF
