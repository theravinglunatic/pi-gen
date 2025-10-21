# Pre-Build Checklist

Before running `sudo ./build.sh`, verify these items:

## ✅ Configuration

- [ ] `config` file exists with correct settings
  - `IMG_NAME='noface-pi5'`
  - `RELEASE='trixie'`
  - `FIRST_USER_NAME='noface'`
  - `STAGE_LIST="stage0 stage1 stage2 stage3"`

- [ ] SSH public key is set in `config`:
  - `PUBKEY_SSH_FIRST_USER` contains your public key
  - `PUBKEY_ONLY_SSH=1` is set

## ✅ Stage3 Files

- [ ] All scripts are executable:
  ```bash
  ls -la stage3/01-clone-app/01-run.sh
  ls -la stage3/02-setup-service/01-run.sh
  ls -la stage3/01-clone-app/files/setup-faceless.sh
  # All should show -rwxr-xr-x
  ```

- [ ] Package lists are populated:
  ```bash
  cat stage3/00-install-packages/00-packages
  cat stage3/00-install-packages/00-packages-nr
  # Should contain package names
  ```

- [ ] NetworkManager profiles exist:
  ```bash
  ls stage3/02-setup-service/files/*.nmconnection
  # Should show Production-eth0.nmconnection and Development-eth1.nmconnection
  ```

- [ ] SystemD service file exists:
  ```bash
  cat stage3/02-setup-service/files/no_face_core.service
  # Should contain [Unit], [Service], [Install] sections
  ```

- [ ] Unused directories have SKIP files:
  ```bash
  ls stage3/*/SKIP
  # Should show 00-install-dependencies/SKIP and 01-print-support/SKIP
  ```

## ✅ System Requirements

- [ ] Running on Debian-based Linux system
- [ ] 4K page size kernel (check: `getconf PAGESIZE`)
- [ ] At least 50GB free disk space
- [ ] All dependencies installed:
  ```bash
  apt list --installed 2>/dev/null | grep -E '(debootstrap|qemu-user-static|parted|zerofree)'
  ```

## ✅ Build Environment

- [ ] No spaces in base path (check: `pwd`)
- [ ] Building on Linux filesystem (not NTFS)
- [ ] Running as root or with sudo
- [ ] Internet connection available (for package downloads)

## 🚀 Ready to Build

If all items are checked, run:

```bash
sudo ./build.sh
```

Expected build time: 1-2 hours (depending on system)

## 📝 Build Logs

Monitor build progress:
```bash
# In another terminal
tail -f work/noface-pi5-trixie-armhf/build.log
```

## ✅ Post-Build Verification

After build completes:

- [ ] Image file exists:
  ```bash
  ls -lh deploy/image_*-noface-pi5*.img.xz
  ```

- [ ] Check stage3 was executed:
  ```bash
  grep -i "stage3" work/noface-pi5-trixie-armhf/build.log
  ```

- [ ] Verify packages were installed:
  ```bash
  ls work/noface-pi5-trixie-armhf/stage3/rootfs/usr/bin/mpv
  ls work/noface-pi5-trixie-armhf/stage3/rootfs/usr/bin/node
  ```

- [ ] Verify NetworkManager profiles:
  ```bash
  ls -la work/noface-pi5-trixie-armhf/stage3/rootfs/etc/NetworkManager/system-connections/
  ```

- [ ] Verify setup script installed:
  ```bash
  ls -la work/noface-pi5-trixie-armhf/stage3/rootfs/usr/local/bin/setup-faceless.sh
  ```

- [ ] Verify instructions file:
  ```bash
  cat work/noface-pi5-trixie-armhf/stage3/rootfs/home/noface/SETUP_INSTRUCTIONS.txt
  ```

## 🚨 Common Build Issues

### Issue: "debootstrap failed"
**Solution:** Check internet connection, verify RELEASE='trixie' is correct

### Issue: "Permission denied" on scripts
**Solution:** Run `chmod +x stage3/*/01-run.sh stage3/*/files/*.sh`

### Issue: Package not found
**Solution:** Verify package name exists in Debian Trixie repository

### Issue: Out of space
**Solution:** Clean previous builds: `sudo rm -rf work/ deploy/`

## 📚 Next Steps After Successful Build

1. Flash image to SD card using Raspberry Pi Imager or dd
2. Follow deployment instructions in `stage3/README.md`
3. Run first-boot setup script after SSH login
4. Verify service is running

---

**Need help?** Check:
- `stage3/README.md` - Stage3 documentation
- `.github/copilot-instructions.md` - AI agent guide
- `.github/DEPLOYMENT.md` - Full deployment reference
