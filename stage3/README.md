# Stage3: FacelessWebServer Automation

This custom stage3 configures a headless Raspberry Pi OS Lite image for FacelessWebServer deployment without installing the desktop environment.

## Directory Structure

```
stage3/
├── 00-install-packages/
│   ├── 00-packages           # System packages (with recommends)
│   └── 00-packages-nr        # Minimal packages (no recommends)
│
├── 01-clone-app/
│   ├── files/
│   │   └── setup-faceless.sh # Manual setup (deprecated)
│   └── 01-run.sh             # Install instructions
│
├── 03-first-boot/
│   ├── files/
│   │   ├── faceless-first-boot.service  # SystemD one-shot service
│   │   └── faceless-first-boot.sh       # Automated USB setup
│   └── 01-run.sh             # Install first-boot automation
│
└── 02-setup-service/
    ├── files/
    │   ├── Production-eth0.nmconnection    # Static IP config
    │   ├── Development-eth1.nmconnection   # DHCP config
    │   └── no_face_core.service            # SystemD service
    └── 01-run.sh             # Install configs, enable services
```

## What Gets Automated

### ✅ Fully Automated in Image Build

1. **System Packages** (`00-install-packages/`)
   - mpv media player + development libraries
   - NetworkManager (replaces dhcpcd)
   - Python 3 + pip + development tools
   - Node.js + npm
   - GPIO libraries (gpiozero, lgpio)
   - System utilities (git, vim, htop, etc.)

2. **Network Configuration** (`02-setup-service/`)
   - NetworkManager connection profiles
   - eth0: Static IP 192.168.8.2/24 (production network)
   - eth1: DHCP (development network)
   - Disabled: dhcpcd, dnsmasq, hostapd (prevent conflicts)

3. **System Services** (`02-setup-service/`)
   - Enabled: NetworkManager, avahi-daemon, udisks2
   - Disabled: dhcpcd, dnsmasq, hostapd, bluetooth
   - SystemD service template installed (not enabled yet)

4. **User Configuration**
   - noface user with SSH key-only auth
   - Proper group memberships (gpio, video, audio, etc.)
   - SSH directory prepared for deploy key
   - GitHub added to known_hosts

### Security Rationale

**Why USB Drive Method?**
1. **Private key never exposed in public image** - Keeps the pi-gen fork publishable
2. **Physical security** - SSH key on removable media under your control
3. **Full development access** - Personal key provides read/write for git operations
4. **VS Code remote development** - Enables seamless remote editing and git push
5. **Zero manual steps post-deployment** - Fully automated after USB preparation

**Development vs Production:**
- **This Build (Development):** Personal SSH key provides full git access for remote development
- **Future Production:** Should use read-only deploy key instead

**VS Code Remote Development:**
Once deployed, you can develop remotely:
```bash
# Connect via SSH
code --remote ssh-remote+noface@noface.local /home/noface/facelessWebServer

# Or use VS Code UI: Remote-SSH → noface@noface.local
# Git operations (push, pull, fetch) work seamlessly
```

#### Deployment Workflow (Fully Automated)

1. **Flash SD card** with generated image
2. **Insert prepared USB drive** (with `.deploy/deploy_key`)
3. **Insert SD card** into Raspberry Pi 5
4. **Connect networks** (eth0 to GL.iNet, eth1 to home router)
5. **Power on** → Automatic setup begins

**First-Boot Service (`faceless-first-boot.service`) does:**
- ⏱️  Waits for USB drive (up to 2 minutes)
- 🔑 Loads personal SSH key from USB `.deploy/deploy_key`
- � Configures SSH for GitHub access
- 📥 Clones `git@github.com:theravinglunatic/facelessWebServer.git`
- 🐍 Installs Python dependencies (system-wide)
- 📦 Installs Node.js dependencies
- 🔤 Installs VCR EAS font (if present)
- ⚙️  Enables and starts `no_face_core.service`
- ✅ Creates completion marker (runs once only)
- 📝 Logs everything to `/var/log/faceless-first-boot.log`

**Total intervention: ~1 minute** (just preparing USB once)

## Key Design Decisions

### No Desktop Environment
This image is **headless** (Lite base only). No X11, Wayland, or GUI packages.
- FacelessWebServer originally required desktop for display/audio
- This image prepares for **transition to headless** operation
- Future: Use DRM/KMS for direct video output (no X11)

### No Python Virtual Environment
Since this is a **purpose-built image** for a single application:
- Python packages installed system-wide
- No venv overhead
- pip configured with `break-system-packages = true`
- Simpler systemd service configuration

### MPV Instead of VLC
Transitioning from VLC to MPV for better headless support:
- MPV has better command-line interface
- Lighter weight for headless operation
- Better integration with DRM/KMS

### NetworkManager Required
**Critical:** This setup uses NetworkManager for dual-ethernet configuration.
- dhcpcd **must be disabled** (conflicts with dual-NIC routing)
- dnsmasq **must be disabled** (DNS conflicts)
- Connection profiles define static IP and routing metrics

### USB Deploy Key Method
Chosen for maximum security and automation:
- **Alternative rejected:** Clone during build (exposes private repo in public image)
- **Alternative rejected:** Embed credentials (security risk)
- **Alternative rejected:** Manual SSH key transfer (requires user intervention)
- **Chosen:** USB-based deploy key (secure + 95% automated)

**How it works:**
1. Private SSH key stored on USB drive (physically secure)
2. First-boot service loads key from USB automatically
3. Clones repository and configures system
4. Key never exposed in public image
5. USB travels with video content (minimal overhead)

## Building the Image

```bash
# From pi-gen root directory
sudo ./build.sh

# Output: deploy/image_YYYY-MM-DD-noface-pi5-lite.img.xz
```

## Testing the Build

After building, you can test the stage3 configuration:

```bash
# Check packages were installed
grep -r "mpv\|network-manager" work/noface-pi5-trixie-armhf/stage3/rootfs/var/log/apt/

# Check NetworkManager profiles exist
ls -la work/noface-pi5-trixie-armhf/stage3/rootfs/etc/NetworkManager/system-connections/

# Check service file installed
cat work/noface-pi5-trixie-armhf/stage3/rootfs/etc/systemd/system/no_face_core.service

# Check setup script installed
ls -la work/noface-pi5-trixie-armhf/stage3/rootfs/usr/local/bin/setup-faceless.sh
```

## Troubleshooting

### Build Fails in Stage3
- Check all `01-run.sh` scripts are executable (`chmod +x`)
- Check package names are valid for Debian Trixie
- View build log: `cat work/noface-pi5-trixie-armhf/build.log`

### NetworkManager Conflicts
If networking doesn't work after boot:
- Verify dhcpcd is disabled: `systemctl status dhcpcd`
- Check connection profiles: `nmcli connection show`
- View NetworkManager logs: `journalctl -u NetworkManager`

### Service Won't Start
- Repository must be cloned first (run setup script)
- Check service status: `systemctl status no_face_core`
- View logs: `journalctl -u no_face_core -f`

## References

- Main documentation: `/.github/DEPLOYMENT.md`
- Build instructions: `/README.md`
- Copilot guidance: `/.github/copilot-instructions.md`
