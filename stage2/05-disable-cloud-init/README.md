# Cloud-Init Disable Script

## Purpose

This script completely disables cloud-init in the custom Raspberry Pi image to prevent conflicts with our custom first-boot automation system (`faceless-first-boot.service`).

## Why This is Necessary

### The Problem

**Raspberry Pi Imager** automatically adds cloud-init configuration files when flashing images:
- Creates `/boot/firmware/user-data`
- Creates `/boot/firmware/meta-data`
- Creates `/boot/firmware/network-config`

These files cause cloud-init to run with **Imager's configuration** instead of our custom first-boot script, breaking the USB-based deployment key system and repository cloning automation.

### The Solution

This script:
1. ✅ Creates `/etc/cloud/cloud-init.disabled` marker file
2. ✅ Masks all cloud-init systemd services
3. ✅ Removes cloud-init package entirely

## Impact

- ❌ Cloud-init will NOT run (intended behavior)
- ✅ Custom `faceless-first-boot.service` will handle all setup
- ✅ USB-based deployment key system will work correctly
- ✅ Repository cloning automation will function as designed

## CRITICAL: Flashing Instructions

**DO NOT use Raspberry Pi Imager** to flash this image, or cloud-init will be re-enabled with wrong configuration.

### ✅ Correct Method: Use dd or bmaptool

```bash
# Method 1: dd (handles .xz compression)
sudo dd if=deploy/image_*.img.xz of=/dev/sdX bs=4M status=progress conv=fsync

# Method 2: bmaptool (faster)
sudo bmaptool copy deploy/image_*.img.xz /dev/sdX
```

### ❌ WRONG: Raspberry Pi Imager
**Do not use:** `rpi-imager` - This will add cloud-init files and break automation.

## Verification

After flashing and booting, verify cloud-init is disabled:

```bash
# Check disable marker exists
ssh noface@noface.local "ls -la /etc/cloud/cloud-init.disabled"

# Verify services are masked
ssh noface@noface.local "systemctl status cloud-init.service"
# Should show: "Loaded: masked"

# Check package is removed
ssh noface@noface.local "dpkg -l | grep cloud-init"
# Should show nothing or "rc" (removed but config remains)
```

## Related Files

- **First-boot service:** `stage3/03-first-boot/files/faceless-first-boot.service`
- **First-boot script:** `stage3/03-first-boot/files/faceless-first-boot.sh`
- **USB structure:** Requires `.deploy/deploy_key` and `Videos/` directory
