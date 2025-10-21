# USB Deploy Key Quick Reference

## 1. Prepare USB Drive (One-Time Setup)

```bash
# Copy your personal SSH key to USB (provides full read/write access)
USB_PATH="/path/to/usb"
mkdir -p "$USB_PATH/.deploy"
cp ~/.ssh/id_ed25519 "$USB_PATH/.deploy/deploy_key"
chmod 600 "$USB_PATH/.deploy/deploy_key"

# Note: This is a DEVELOPMENT image. Your personal key provides
# full access for git push/pull operations and VS Code remote development.
```

## 🏗️ Build Image (~1-2 hours)

```bash
cd /home/lunatic/pi-gen
./verify-build.sh    # Check prerequisites
sudo ./build.sh      # Build image
```

## 🚀 Deploy (3-5 minutes automated)

```bash
# Flash SD card
sudo dd if=deploy/image_*-noface-pi5*.img.xz of=/dev/sdX bs=4M status=progress

# Insert hardware:
# 1. SD card → Pi 5
# 2. USB drive (with .deploy/deploy_key)
# 3. eth0 → GL.iNet router
# 4. eth1 → Home router
# 5. Power on

# Wait 3-5 minutes → Fully configured!
```

## ✅ Verify

```bash
ssh noface@noface.local
systemctl status no_face_core
cat /var/log/faceless-first-boot.log
```

## USB Drive Structure

```
/media/usb0/
├── videos/              # Video content
│   ├── video1.mp4
│   └── video2.mp4
└── .deploy/             # Hidden directory
    └── deploy_key       # Your personal SSH key (chmod 600)
```

## Security Notes

- Personal SSH key on USB provides full read/write access
- Suitable for development/transition image (not production)
- Enables VS Code remote development and git push operations
- Keep USB drive secure (contains your personal credentials)
- No credentials in public image or version control
- Full git access for remote development workflow

---

**Full documentation:** `stage3/README.md` and `IMPLEMENTATION_SUMMARY.md`
