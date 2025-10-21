# pi-gen AI Development Guide

## Project Overview
pi-gen is a Raspberry Pi OS image builder using staged filesystem construction with chroot operations. It creates bootable SD card images from Debian repositories through a multi-stage build pipeline.

**This Fork:** Custom image builder for FacelessWebServer deployment. Creates a **headless development image** (Lite base) that automates system preparation for transitioning a desktop-dependent multimedia application to headless operation. Target hardware: Raspberry Pi 5.

## Architecture & Build Flow

### Stage-Based Build System
Images are built sequentially through stages (0-5), each building on the previous:
- **stage0**: Bootstrap minimal Debian filesystem via `debootstrap`
- **stage1**: Make system bootable (bootloader, fstab, networking)
- **stage2**: Lite system (produces `-lite` image via `EXPORT_IMAGE` marker) - **Primary target for this fork**
- **stage3**: Desktop environment (X11, LXDE) - **Not used in this fork's headless build**
- **stage4**: Full system (4GB card target, documentation)
- **stage5**: Complete system (development tools, LibreOffice)

**This Fork's Build:** `STAGE_LIST="stage0 stage1 stage2 stage3"` where stage3 contains custom automation for FacelessWebServer (without desktop environment).

### Build Control Files
Within each stage directory, subdirectories execute in alphanumeric order:
- `XX-run.sh`: Executable scripts run on host
- `XX-run-chroot.sh`: Scripts executed inside image chroot via `on_chroot` function
- `XX-packages`: Package list installed with recommends
- `XX-packages-nr`: Packages installed with `--no-install-recommends`
- `XX-debconf`: Debconf configuration
- `XX-patches/`: Quilt patch sets

**Stage control markers:**
- `SKIP`: Skip entire stage directory
- `SKIP_IMAGES`: Skip image export (use during development)
- `EXPORT_IMAGE`: Generate image at this stage (defines `IMG_SUFFIX` variable)
- `EXPORT_NOOBS`: Generate NOOBS bundle

### Critical Build Functions (scripts/common)
- `bootstrap()`: Invokes debootstrap with armhf arch and Raspberry Pi keyring
- `on_chroot()`: Mounts proc/dev/sys/tmp into rootfs and executes commands in chroot via `setarch linux32 capsh`
- `copy_previous()`: Rsync previous stage rootfs to current (excludes apt cache)
- `unmount()` / `unmount_image()`: Cleanup mounted filesystems and loop devices

## Development Workflows

### Building Images
```bash
# Native build (requires Debian-based system)
./build.sh

# Docker build (works on non-Debian systems)
./build-docker.sh

# Use custom config
./build.sh -c myconfig
```

### Rapid Development Iteration
To work on specific stage without rebuilding everything:
1. Create `SKIP_IMAGES` in stage2/4/5 directories
2. Add `SKIP` files to stages you're not modifying
3. Run full build once
4. Add `SKIP` to earlier completed stages
5. Rebuild only changed stage: `sudo CLEAN=1 ./build.sh`
6. For Docker: `PRESERVE_CONTAINER=1 CONTINUE=1 CLEAN=1 ./build-docker.sh`

### Configuration (config file)
Key variables:
- `IMG_NAME`: Base image name (default: `raspios-$RELEASE-$ARCH`, this fork uses `noface-pi5`)
- `STAGE_LIST`: Override stage order (this fork: `"stage0 stage1 stage2 stage3"`)
- `RELEASE`: Debian release (default: `trixie`, **must match branch** - see Common Gotchas)
- `FIRST_USER_NAME`/`FIRST_USER_PASS`: Default user credentials (this fork: `noface`/set in config)
- `ENABLE_SSH`, `PUBKEY_SSH_FIRST_USER`, `PUBKEY_ONLY_SSH`: SSH configuration (this fork: SSH key-only)
- `DEPLOY_COMPRESSION`: Output format (`zip`|`gz`|`xz`|`none`, this fork uses `xz`)
- `TARGET_HOSTNAME`: System hostname (this fork: `noface`)

## Project-Specific Patterns

### FacelessWebServer Integration
This fork builds a **headless development image** for transitioning FacelessWebServer from desktop to headless operation:
- **Base:** Raspberry Pi OS Lite (stage2) - no desktop environment
- **Custom Stage3:** Automated setup scripts for application deployment
- **Target Hardware:** Raspberry Pi 5 with dual ethernet, USB camera, GPIO rotary encoder
- **Network Architecture:** Dual-NIC setup (isolated production network + development network)
- **Key Services:** Python backend (WebSocket), Node.js web server, media players (VLC/MPV preparation)

### User Configuration
The current config creates user `noface` with SSH key auth only. User setup happens in `stage1/01-sys-tweaks/00-run.sh` via `adduser` in chroot, and SSH keys are configured in `stage2/01-sys-tweaks/01-run.sh`.

### Custom Stage3 Automation Directories
This repo has custom directories in stage3 for FacelessWebServer deployment:
- `00-install-packages/`: System packages (Python, Node.js, NetworkManager, GPIO libraries, media tools)
- `01-clone-app/`: Repository cloning and dependency installation (Python venv, npm packages)
- `02-setup-service/files/`: Configuration files (systemd services, NetworkManager profiles)
- `02-setup-service/`: Service installation and system configuration scripts

**Automation Philosophy:** Maximize automated setup in image to minimize post-deployment manual steps. The image should be ready to run the application after inserting USB storage and connecting hardware.

### Critical Configuration Files Created in Stage3
Files that must be created during image build:
1. **NetworkManager Connection Profiles** (`/etc/NetworkManager/system-connections/`)
   - `Production-eth0.nmconnection`: Static IP 192.168.8.2/24 (isolated network)
   - `Development-eth1.nmconnection`: DHCP (development/internet access)
   - **Critical:** Must disable dhcpcd/dnsmasq to avoid conflicts

2. **Systemd Service** (`/etc/systemd/system/no_face_core.service`)
   - Runs Python backend as user `noface`
   - Environment variables for future display/audio access (currently unused in headless)

3. **Package Installation Patterns**
   - Use `00-packages` for packages with recommends
   - Use `00-packages-nr` for minimal installs (Python, Node.js)
   - Comments in package files use `#` (filtered by `remove-comments.sed`)

### Stage3 Directory Execution Pattern
Scripts execute in alphanumeric order across all subdirectories:
```
stage3/00-install-packages/00-packages       # Install system packages
stage3/01-clone-app/01-run.sh                # Clone repo, setup venv, npm install
stage3/02-setup-service/files/               # Configuration files (not executed)
stage3/02-setup-service/01-run.sh            # Install configs, enable services
```

**Important:** All `XX-run.sh` scripts must be executable (`chmod +x`) or they'll be skipped.

### Image Export Process
Image generation (`export-image/`) happens after stages complete:
1. `prerun.sh`: Creates empty IMG_FILE, partitions it (FAT32 boot + ext4 root)
2. Mounts via loop device, rsync from stage rootfs
3. `05-finalise/01-run.sh`: Cleans logs, generates initramfs, runs zerofree, compresses

### Architecture Constraints
- **Must build on 4K page size kernel** for armhf images (check with `getconf PAGESIZE`)
- Requires `binfmt_misc` + `qemu-user-static` for cross-architecture builds
- Base path **cannot contain spaces** (debootstrap limitation)
- Working directory must be Linux filesystem (not NTFS)

## Common Gotchas

1. **RELEASE mismatch**: Config `RELEASE` must match branch intent (`trixie` for main branch, `bookworm` for bookworm branch). This fork uses `trixie` on main.
2. **File permissions**: Run scripts must be executable (`chmod +x XX-run.sh`) - common issue with git clones
3. **Chroot environment**: Network/special filesystems don't persist between `on_chroot` calls - must remount for each operation
4. **Package comments**: Lines starting with `#` in package files are ignored (use `remove-comments.sed` filter)
5. **Clean builds**: Set `CLEAN=1` to force rebuild of stage (deletes existing rootfs) - essential when iterating on stage3
6. **NetworkManager conflicts**: Must disable dhcpcd/dnsmasq or dual-NIC routing will fail
7. **Service ordering**: Use systemd `After=` dependencies carefully - FacelessWebServer needs network before starting

## Adding Packages
Place package names in `00-packages` or `00-packages-nr` (one per line or space-separated):
```
# in stage3/00-install-packages/00-packages
nginx
python3-pip
```

## Adding Services
1. Create systemd unit in `stage3/02-setup-service/files/myapp.service`
2. Create install script `stage3/02-setup-service/01-run.sh`:
```bash
#!/bin/bash -e
install -m 644 files/myapp.service "${ROOTFS_DIR}/etc/systemd/system/"
on_chroot << EOF
systemctl enable myapp.service
EOF
```

## Dependencies
Install via: `apt install coreutils quilt parted qemu-user-static debootstrap zerofree zip dosfstools e2fsprogs libarchive-tools libcap2-bin grep rsync xz-utils file git curl bc gpg pigz xxd arch-test bmap-tools kmod`

Full list maintained in `depends` file (format: `tool[:debian-package]`).
