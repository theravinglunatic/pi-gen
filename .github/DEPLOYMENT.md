# FacelessWebServer Deployment Guide

**Purpose:** Deploy FacelessWebServer on a fresh Raspberry Pi OS image with minimal manual intervention.

**Target Platform:** Raspberry Pi 4/5 with Raspberry Pi OS Bookworm (Desktop)  
**Last Updated:** October 21, 2025  
**Deployment Method:** Custom Pi image with pre-configured settings

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Base Image Configuration](#base-image-configuration)
3. [Network Configuration](#network-configuration)
4. [User and Permissions](#user-and-permissions)
5. [System Services](#system-services)
6. [Audio Configuration](#audio-configuration)
7. [Display and Graphics](#display-and-graphics)
8. [Hardware Access](#hardware-access)
9. [Software Dependencies](#software-dependencies)
10. [Application Setup](#application-setup)
11. [Post-Deployment Verification](#post-deployment-verification)
12. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Hardware
- **Raspberry Pi:** Pi 4 or Pi 5 (tested on both)
- **Storage:** Minimum 8GB SD card (16GB+ recommended)
- **Network:**
  - eth0: Onboard Ethernet (GL.iNet router connection)
  - eth1: USB-Ethernet adapter (development/Internet access)
- **Camera:** USB camera (tested: Arducam 16MP, any v4l2 compatible)
- **Rotary Encoder:** KY-040 connected to GPIO pins 17, 18, 27
- **Display:** HDMI display for fullscreen video output
- **USB Storage:** USB flash drive with specific directory structure

### Network Hardware
- **GL.iNet GL-AR300M16-Ext Router** (or compatible)
  - Operating Mode: **Router Mode** (not Access Point Mode)
  - WAN: Disconnected (isolated network)
  - LAN: 192.168.8.1/24 (DHCP server for visitors)
  - Pi connected to LAN port: 192.168.8.2/24 (static)

### Software
- **Base OS:** Raspberry Pi OS Bookworm (64-bit, Desktop version)
- **Python:** 3.11.x (system Python)
- **Node.js:** 18.20.x (from apt repositories)

---

## Base Image Configuration

### Initial Setup (Pi Imager or Manual)

**Using Raspberry Pi Imager:**
1. Select **Raspberry Pi OS (64-bit) with Desktop**
2. Configure settings (⚙️):
   - Hostname: `noface`
   - Username: `noface`
   - Password: [your choice]
   - WiFi: Skip/disable (handled post-boot)
   - Locale: Set timezone and keyboard layout
   - SSH: Enable with password authentication

**Boot Configuration (`/boot/firmware/config.txt`):**
```ini
# Audio
dtparam=audio=on

# Camera
camera_auto_detect=1

# Display
display_auto_detect=1
disable_overscan=1

# Graphics
dtoverlay=vc4-kms-v3d
max_framebuffers=2
disable_fw_kms_setup=1

# System
arm_64bit=1
arm_boost=1
usb_max_current_enable=1

# CM4/CM5 specific
[cm4]
otg_mode=1

[cm5]
dtoverlay=dwc2,dr_mode=host

[all]
```

### Hostname Configuration

**Set hostname to `noface`:**
```bash
# /etc/hostname
noface
```

**Enable mDNS resolution:**
- Avahi daemon must be enabled (default on Pi OS Desktop)
- Accessible as `noface.local` on network

---

## Network Configuration

### Critical: Single Network Manager

**DISABLE these services (conflicts with NetworkManager):**
```bash
sudo systemctl disable --now dhcpcd
sudo systemctl disable --now dnsmasq
sudo systemctl mask hostapd
```

**ENABLE NetworkManager:**
```bash
sudo systemctl enable --now NetworkManager
```

### NetworkManager Connection Profiles

**⚠️ CRITICAL: These must be created BEFORE first boot with hardware attached.**

#### eth0 (Production Network) - Static IP

**File:** `/etc/NetworkManager/system-connections/Production-eth0.nmconnection`
```ini
[connection]
id=Production-eth0
uuid=8c6591fe-b4ce-36a7-bff1-dd3e82c11cc0
type=ethernet
autoconnect-priority=-999
interface-name=eth0

[ethernet]

[ipv4]
address1=192.168.8.2/24
method=manual
never-default=true
route-metric=101

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
```

**Set permissions:**
```bash
sudo chmod 600 /etc/NetworkManager/system-connections/Production-eth0.nmconnection
sudo chown root:root /etc/NetworkManager/system-connections/Production-eth0.nmconnection
```

#### eth1 (Development Network) - DHCP

**File:** `/etc/NetworkManager/system-connections/Development-eth1.nmconnection`
```ini
[connection]
id=Development-eth1
uuid=14ed9f06-af87-3b1c-a899-ea0878efa547
type=ethernet
autoconnect-priority=-999
interface-name=eth1

[ethernet]

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
```

**Set permissions:**
```bash
sudo chmod 600 /etc/NetworkManager/system-connections/Development-eth1.nmconnection
sudo chown root:root /etc/NetworkManager/system-connections/Development-eth1.nmconnection
```

### Network Architecture Summary

**Production Network (eth0):**
- Static IP: `192.168.8.2/24`
- Gateway: None (`never-default=true`)
- Route Metric: 101 (lower priority)
- Purpose: Visitor WiFi access via GL.iNet router
- **NO INTERNET ACCESS** (isolated network)

**Development Network (eth1):**
- DHCP from home router
- Gets default gateway automatically
- Route Metric: 100 (higher priority - becomes default route)
- Purpose: Development, GitHub access, updates
- **INTERNET ACCESS** (when connected)

**Expected Routing Table:**
```bash
ip route show
# Should output:
default via 192.168.1.1 dev eth1 metric 100  # ONLY default route
192.168.1.0/24 dev eth1 metric 100
192.168.8.0/24 dev eth0 metric 101           # NO default gateway
```

### WiFi Configuration

**WiFi State:** Disabled for production (optional for development)

**To disable onboard WiFi permanently:**
```bash
# Method 1: NetworkManager (software disable)
sudo nmcli radio wifi off

# Method 2: rfkill (hardware disable)
sudo rfkill block wifi

# Method 3: Boot config (prevents driver load)
# Add to /boot/firmware/config.txt:
dtoverlay=disable-wifi
```

**Note:** GL.iNet router provides WiFi for visitors. Pi WiFi not needed.

### Avahi/mDNS Configuration

**Service:** `avahi-daemon.service`
```bash
sudo systemctl enable avahi-daemon
```

**Configuration:** Default settings work (no changes needed)
- Hostname automatically advertised as `noface.local`
- Enabled on all interfaces (eth0, eth1 if present)

---

## User and Permissions

### User Configuration

**Username:** `noface`  
**UID:** 1000 (default first user)  
**GID:** 1000  
**Home:** `/home/noface`

### Required Group Memberships

**User `noface` must be member of these groups:**
```bash
# Core groups
sudo usermod -aG adm noface         # System logs access
sudo usermod -aG sudo noface        # Sudo privileges
sudo usermod -aG dialout noface     # Serial port access (if needed)

# Hardware access
sudo usermod -aG gpio noface        # GPIO devices (rotary encoder)
sudo usermod -aG video noface       # Camera access (/dev/video*)
sudo usermod -aG audio noface       # Audio devices
sudo usermod -aG render noface      # GPU rendering
sudo usermod -aG input noface       # Input devices

# System resources
sudo usermod -aG plugdev noface     # USB device access
sudo usermod -aG netdev noface      # Network device configuration
sudo usermod -aG spi noface         # SPI devices (if used)
sudo usermod -aG i2c noface         # I2C devices (if used)
```

**Verify group membership:**
```bash
groups noface
# Expected output:
# noface adm dialout cdrom sudo audio video plugdev games users input render netdev spi i2c gpio lpadmin
```

### Autologin Configuration

**File:** `/etc/lightdm/lightdm.conf`
```ini
[Seat:*]
autologin-user=noface
autologin-session=LXDE-pi-labwc
```

**Purpose:** Auto-login to GUI for X11 display server access

---

## System Services

### Core Service: no_face_core.service

**File:** `/etc/systemd/system/no_face_core.service`
```ini
[Unit]
Description=No Face Core Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/home/noface/facelessWebServer/venv/bin/python /home/noface/facelessWebServer/no_face_core/main.py
WorkingDirectory=/home/noface/facelessWebServer
StandardOutput=journal
StandardError=journal
Restart=always
TimeoutStopSec=5
KillSignal=SIGINT
SendSIGKILL=yes
User=noface
Group=noface

# Environment variables for GUI access
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/noface/.Xauthority"
Environment="PULSE_SERVER=unix:/run/user/1000/pulse/native"
Environment="XDG_RUNTIME_DIR=/run/user/1000"

# Allow binding to privileged ports (port 80)
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

**Enable the service:**
```bash
sudo systemctl enable no_face_core.service
```

**Service Dependencies:**
- `network-online.target`: Wait for network (eth0) to be configured
- User session must be active (autologin provides this)

### Disabled Services

**These services MUST be disabled/masked:**
```bash
# Network managers (conflict with NetworkManager)
sudo systemctl disable --now dhcpcd
sudo systemctl disable --now dnsmasq
sudo systemctl mask hostapd

# Bluetooth (optional, saves resources)
sudo systemctl disable --now bluetooth
```

### Required Services

**These services MUST be enabled:**
```bash
# Network management
sudo systemctl enable NetworkManager
sudo systemctl enable NetworkManager-wait-online

# mDNS hostname resolution
sudo systemctl enable avahi-daemon

# Display manager (for X11)
sudo systemctl enable lightdm

# Audio (PipeWire replaces PulseAudio)
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse

# USB automount
sudo systemctl enable udisks2
```

---

## Audio Configuration

### Audio System: PipeWire (PulseAudio Replacement)

**Current Status:** Pi OS Bookworm uses PipeWire by default

**Required Services (user-level):**
```bash
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
```

**PulseAudio Compatibility:**
- PipeWire provides PulseAudio API compatibility
- Application code uses `python-vlc` with `--aout=pulse`
- Environment variable: `PULSE_SERVER=unix:/run/user/1000/pulse/native`

**Audio Output Device:**
- Default: HDMI audio (via vc4-kms-v3d driver)
- Fallback: 3.5mm headphone jack (`alsa_output.platform-fe00b840.mailbox.stereo-fallback`)

**Test Audio:**
```bash
pactl info  # Should show "PulseAudio (on PipeWire)"
pactl list sinks short  # List audio output devices
```

**No Additional Configuration Required:** Works out-of-box with PipeWire.

---

## Display and Graphics

### Display Manager: LightDM

**Service:** `lightdm.service`
```bash
sudo systemctl enable lightdm
```

**Compositor:** Wayland (labwc) - Default on Pi OS Bookworm
- Session: `LXDE-pi-labwc`
- X11 compatibility: Xwayland (provides DISPLAY=:0)

### X11 Environment

**Required Environment Variables (set in systemd service):**
```bash
DISPLAY=:0
XAUTHORITY=/home/noface/.Xauthority
XDG_RUNTIME_DIR=/run/user/1000
```

**X11 Process Tree:**
```
lightdm → labwc (Wayland) → Xwayland :0
```

**Application Behavior:**
- VLC uses `--no-xlib` (runs headless via DRM/KMS)
- MPV uses `vo='x11'` (requires Xwayland)
- Tkinter creates windows on :0 display

### Graphics Driver

**Driver:** vc4-kms-v3d (Broadcom VideoCore KMS)
- Boot config: `dtoverlay=vc4-kms-v3d`
- Provides GPU acceleration for rendering
- Enables fullscreen video without X11 dependency (VLC)

**Framebuffer Configuration:**
```bash
# /boot/firmware/config.txt
max_framebuffers=2
disable_fw_kms_setup=1
```

---

## Hardware Access

### GPIO Configuration

**Library:** gpiozero (Python)
- Uses `lgpio` backend (default on Pi OS Bookworm)
- No root required (user in `gpio` group)

**Device Files:**
```bash
/dev/gpiochip0  # Main GPIO chip
/dev/gpiochip1  # Secondary GPIO chip
```

**Permissions:**
- Owner: `root:gpio`
- Mode: `crw-rw----` (660)
- User `noface` in `gpio` group

**Rotary Encoder Pins:**
- GPIO 17: CLK (clock)
- GPIO 18: DT (data)
- GPIO 27: SW (button) - currently unused

**No Additional Configuration Required:** Works with gpiozero defaults.

### Camera Access

**Device:** `/dev/video0` (primary camera)
- Multiple `/dev/video*` devices (different formats/modes)
- Permissions: `root:video`, mode `crw-rw----` (660)
- User `noface` in `video` group

**Camera Interface:**
- VLC v4l2 direct access: `v4l2:///dev/video0:chroma=MJPG:width=1280:height=960:fps=30`
- No additional drivers needed (USB UVC camera)

**Test Camera:**
```bash
v4l2-ctl --list-devices
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

### USB Storage Automount

**Service:** `udisks2.service`
```bash
sudo systemctl enable udisks2
```

**Mount Location:** `/media/noface/<UUID>/`
- Example: `/media/noface/75B9-BBE3/`
- Automatically mounted when USB drive inserted
- Accessible by user `noface` (uid=1000, gid=1000)

**Required Directory Structure on USB Drive:**
```
/media/noface/<UUID>/
├── Videos/                  # Main video pool
│   ├── video1.mp4
│   ├── video2.mp4
│   └── ...
├── staticVideos/            # 50% probability selection
│   ├── static1.mp4
│   └── ...
├── interrupterVideo/        # EAS background video
│   └── InterrupterEAS.mp4
└── interrupterImage/        # Generated overlay images
    └── image.png
```

**File Permissions:** FAT32 filesystem (vfat)
- umask: 0022 (files 644, dirs 755)
- Owner: noface:noface

---

## Software Dependencies

### System Packages (APT)

**Install these packages during image creation:**
```bash
# Python development
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv python3-dev

# VLC and MPV media players
sudo apt-get install -y vlc libvlc-dev mpv libmpv-dev

# Node.js and npm
sudo apt-get install -y nodejs npm

# Network tools
sudo apt-get install -y network-manager avahi-daemon avahi-utils

# Hardware access
sudo apt-get install -y python3-gpiozero python3-lgpio

# USB automount
sudo apt-get install -y udisks2

# Audio (PipeWire - default on Bookworm)
sudo apt-get install -y pipewire pipewire-pulse

# Graphics
sudo apt-get install -y libgl1-mesa-dri

# Build tools (for Python packages)
sudo apt-get install -y build-essential
```

**Package Versions (tested on Bookworm):**
- Python: 3.11.2
- Node.js: 18.20.4
- npm: 9.2.0
- VLC: 3.0.21
- MPV: 0.35.1
- NetworkManager: 1.42.4
- PipeWire: 1.2.7

### Python Virtual Environment

**Location:** `/home/noface/facelessWebServer/venv/`

**Create virtual environment:**
```bash
cd /home/noface/facelessWebServer
python3 -m venv venv
source venv/bin/activate
```

**Install Python packages:**
```bash
# Core dependencies
pip install python-vlc==3.0.21203
pip install python-mpv==1.0.8
pip install websockets
pip install pillow==11.0.0
pip install gpiozero==2.0.1
pip install lgpio==0.2.2.0

# System monitoring (optional but recommended)
pip install psutil==6.1.0
pip install GPUtil==1.4.0

# Logging
pip install systemd-python

# Web framework (if used)
pip install flask==3.1.0
```

**Alternative: Use requirements.txt**
```bash
pip install -r requirements.txt
```

### Node.js Dependencies

**Location:** `/home/noface/facelessWebServer/no_face_remote_client/`

**Install dependencies:**
```bash
cd /home/noface/facelessWebServer/no_face_remote_client
npm install
```

**package.json dependencies:**
```json
{
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

**Installed packages:**
- express@4.17.1 (HTTP server)

---

## Application Setup

### Repository Deployment

**Clone repository:**
```bash
cd /home/noface
git clone https://github.com/theravinglunatic/facelessWebServer.git
cd facelessWebServer
```

**Set permissions:**
```bash
chown -R noface:noface /home/noface/facelessWebServer
chmod -R 755 /home/noface/facelessWebServer
```

### Font Installation

**VCR EAS Font (required for EAS overlays):**

**Source:** `/home/noface/facelessWebServer/no_face_core/fonts/VcrEas-rX3K.ttf`

**Install system-wide:**
```bash
sudo mkdir -p /usr/local/share/fonts/truetype/noface
sudo cp /home/noface/facelessWebServer/no_face_core/fonts/VcrEas-rX3K.ttf \
       /usr/local/share/fonts/truetype/noface/
sudo chmod 644 /usr/local/share/fonts/truetype/noface/VcrEas-rX3K.ttf
sudo fc-cache -fv
```

**Verify installation:**
```bash
fc-list | grep -i "vcr\|eas"
# Should output:
# /usr/local/share/fonts/truetype/noface/VcrEas-rX3K.ttf: VCR EAS:style=Regular
```

**Font is used by:**
- MPV OSD overlay: `osd-font='VCR EAS'`
- PIL text rendering: `ImageFont.truetype()` via fontconfig

### Python Virtual Environment Setup

**Create and activate:**
```bash
cd /home/noface/facelessWebServer
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

**Install all dependencies:**
```bash
# Option 1: Individual packages (see Python Dependencies section above)
pip install python-vlc python-mpv websockets pillow gpiozero lgpio psutil

# Option 2: From requirements.txt (if available)
pip install -r requirements.txt
```

**Deactivate:**
```bash
deactivate
```

**Note:** Systemd service uses absolute path to venv Python: `/home/noface/facelessWebServer/venv/bin/python`

### Node.js Setup

**Install dependencies:**
```bash
cd /home/noface/facelessWebServer/no_face_remote_client
npm install
```

**Test web server:**
```bash
npm start
# Should start server on port 80 (requires CAP_NET_BIND_SERVICE)
```

### Directory Structure

**Expected repository layout:**
```
/home/noface/facelessWebServer/
├── .github/                      # Documentation
│   ├── README.md                 # Documentation index
│   ├── copilot-instructions.md   # Coding standards
│   ├── TECHNICAL_LESSONS.md      # Proven patterns
│   ├── NETWORKING.md             # Network configuration
│   ├── DEPLOYMENT.md             # This file
│   ├── refinement_history.md     # Bug fix history
│   ├── future-plans.md           # Roadmap
│   └── ai-priorities.md          # Performance priorities
│
├── no_face_core/                 # Python backend
│   ├── main.py                   # Entry point
│   ├── ws_server.py              # WebSocket server
│   ├── command_handler.py        # Command processing
│   ├── video_player.py           # VLC/MPV integration
│   ├── rotary_encoder.py         # GPIO hardware
│   ├── utils.py                  # Utilities
│   └── fonts/
│       └── VcrEas-rX3K.ttf       # VCR EAS font
│
├── no_face_remote_client/        # Node.js web server
│   ├── package.json              # Dependencies
│   ├── node_modules/             # Installed packages
│   └── src/
│       ├── server.js             # Express server
│       └── public/               # Static HTML/CSS/JS
│           ├── index.html
│           ├── display.html
│           ├── manual_selection.html
│           ├── styles.css
│           └── ws_client.js
│
├── venv/                         # Python virtual environment
│   ├── bin/python                # Python executable
│   └── lib/python3.11/site-packages/
│
└── legacy_files/                 # Archived old code
```

---

## Post-Deployment Verification

### Service Status Checks

**1. Check systemd service:**
```bash
sudo systemctl status no_face_core.service
# Expected: active (running)
```

**2. Check network configuration:**
```bash
ip addr show eth0
# Expected: 192.168.8.2/24

ip addr show eth1
# Expected: DHCP address from home router (if connected)

ip route show
# Expected: default via <gateway> dev eth1 metric 100
#           192.168.8.0/24 dev eth0 metric 101
```

**3. Check disabled services:**
```bash
systemctl status dhcpcd dnsmasq hostapd
# All should be: inactive (dead)
```

**4. Check audio:**
```bash
pactl info
# Expected: Server Name: PulseAudio (on PipeWire)
```

**5. Check mDNS:**
```bash
avahi-browse -at | grep noface
# Expected: noface.local
```

### Hardware Verification

**6. Check GPIO access:**
```bash
python3 -c "from gpiozero import LED; led = LED(17); print('GPIO OK')"
# Expected: GPIO OK (no errors)
```

**7. Check camera:**
```bash
v4l2-ctl --list-devices
# Expected: Camera device at /dev/video0
```

**8. Check USB mount:**
```bash
ls /media/noface/
# Expected: UUID directory if USB drive inserted
```

### Application Verification

**9. Check web server:**
```bash
curl -I http://localhost
# Expected: HTTP/1.1 200 OK
```

**10. Check WebSocket:**
```bash
# From another machine on network:
curl -I http://noface.local
# Expected: HTTP/1.1 200 OK
```

**11. Check logs:**
```bash
journalctl -u no_face_core.service -n 50
# Should show normal startup messages, no errors
```

### Font Verification

**12. Check font installation:**
```bash
fc-list | grep -i "vcr"
# Expected: /usr/local/share/fonts/truetype/noface/VcrEas-rX3K.ttf: VCR EAS:style=Regular
```

---

## Troubleshooting

### Service Won't Start

**Issue:** `no_face_core.service` fails to start

**Check:**
1. USB drive mounted with correct directory structure?
   ```bash
   ls /media/noface/*/Videos/
   ```
2. Python virtual environment exists?
   ```bash
   ls /home/noface/facelessWebServer/venv/bin/python
   ```
3. Node.js dependencies installed?
   ```bash
   ls /home/noface/facelessWebServer/no_face_remote_client/node_modules/
   ```
4. Check service logs:
   ```bash
   journalctl -u no_face_core.service -n 100 --no-pager
   ```

**Solution:** Service waits for USB drive at boot. If USB not present, it will wait indefinitely (this is expected behavior).

### Network Issues

**Issue:** No Internet access or incorrect routing

**Check routing table:**
```bash
ip route show
```

**Expected output:**
```
default via 192.168.1.1 dev eth1 metric 100  # ONLY default route
192.168.1.0/24 dev eth1 proto kernel scope link src 192.168.1.X metric 100
192.168.8.0/24 dev eth0 proto kernel scope link src 192.168.8.2 metric 101
```

**Fix:**
1. Verify eth1 connected to router with Internet
2. Check NetworkManager connection profiles (see Network Configuration section)
3. Verify dhcpcd/dnsmasq are disabled:
   ```bash
   systemctl status dhcpcd dnsmasq
   # Both should be: inactive (dead), disabled
   ```

**Issue:** Can't access `noface.local`

**Check Avahi:**
```bash
systemctl status avahi-daemon
avahi-browse -at | grep noface
```

**Fix:**
```bash
sudo systemctl restart avahi-daemon
```

### Audio Issues

**Issue:** No audio output

**Check PipeWire:**
```bash
systemctl --user status pipewire pipewire-pulse
pactl info
pactl list sinks short
```

**Fix:**
```bash
systemctl --user restart pipewire pipewire-pulse
```

**Check volume:**
```bash
pactl get-sink-volume @DEFAULT_SINK@
# Should be 0-100%, not 0% (muted)
```

### GPIO/Hardware Issues

**Issue:** Rotary encoder not responding

**Check permissions:**
```bash
groups noface | grep gpio
ls -la /dev/gpiochip0
```

**Fix:**
```bash
sudo usermod -aG gpio noface
# Log out and back in, or reboot
```

**Issue:** Camera not accessible

**Check permissions:**
```bash
groups noface | grep video
ls -la /dev/video0
```

**Fix:**
```bash
sudo usermod -aG video noface
# Log out and back in, or reboot
```

### Display Issues

**Issue:** VLC/MPV can't access display

**Check X11:**
```bash
echo $DISPLAY
# Expected: :0 (when logged in as noface)

ls -la ~/.Xauthority
# Expected: File exists, owned by noface
```

**Fix (if running as service):**
- Service automatically sets DISPLAY=:0
- Requires autologin to be configured
- Check `/etc/lightdm/lightdm.conf` has `autologin-user=noface`

### Font Issues

**Issue:** EAS overlay text not displaying or wrong font

**Check font installation:**
```bash
fc-list | grep -i vcr
```

**Reinstall font:**
```bash
sudo cp /home/noface/facelessWebServer/no_face_core/fonts/VcrEas-rX3K.ttf \
       /usr/local/share/fonts/truetype/noface/
sudo fc-cache -fv
```

---

## Deployment Checklist

### Pre-Image Creation

- [ ] Install Raspberry Pi OS Bookworm (64-bit, Desktop)
- [ ] Set hostname to `noface`
- [ ] Create user `noface` with required groups
- [ ] Configure autologin in LightDM
- [ ] Install all system packages (apt)
- [ ] Disable conflicting services (dhcpcd, dnsmasq, hostapd)
- [ ] Enable required services (NetworkManager, avahi-daemon, udisks2)
- [ ] Create NetworkManager connection profiles (eth0, eth1)
- [ ] Configure boot settings (`/boot/firmware/config.txt`)

### Application Installation

- [ ] Clone repository to `/home/noface/facelessWebServer`
- [ ] Create Python virtual environment
- [ ] Install Python dependencies in venv
- [ ] Install Node.js dependencies (`npm install`)
- [ ] Install VCR EAS font system-wide
- [ ] Create systemd service file (`/etc/systemd/system/no_face_core.service`)
- [ ] Enable systemd service (`systemctl enable no_face_core.service`)
- [ ] Set correct file permissions (noface:noface, 755)

### Post-Image Deployment

**User must configure:**
- [ ] Insert USB drive with video directory structure
- [ ] Connect eth0 to GL.iNet router LAN port
- [ ] Connect eth1 to home router (optional, for Internet)
- [ ] Connect camera to USB port
- [ ] Connect rotary encoder to GPIO pins
- [ ] Connect display via HDMI
- [ ] Power on

**System automatically:**
- [ ] Autologin as `noface`
- [ ] Start X11 display server (Xwayland)
- [ ] Configure network interfaces (eth0 static, eth1 DHCP)
- [ ] Mount USB drive to `/media/noface/<UUID>/`
- [ ] Start `no_face_core.service`
- [ ] Launch web server on port 80
- [ ] Begin video autoplay when USB drive ready

### Verification (After First Boot)

- [ ] Service running: `systemctl status no_face_core.service`
- [ ] Network configured: `ip route show` (default via eth1 only)
- [ ] Web interface accessible: http://noface.local
- [ ] Video playing on display
- [ ] Rotary encoder controls volume
- [ ] Camera accessible (test via web interface)

---

## Configuration Summary

### Files to Create/Modify for Image

**Network:**
- `/etc/NetworkManager/system-connections/Production-eth0.nmconnection`
- `/etc/NetworkManager/system-connections/Development-eth1.nmconnection`
- `/etc/hostname` → `noface`

**Services:**
- `/etc/systemd/system/no_face_core.service`

**Display:**
- `/etc/lightdm/lightdm.conf` → Set autologin-user=noface

**Boot:**
- `/boot/firmware/config.txt` → Audio, camera, graphics settings

**Fonts:**
- `/usr/local/share/fonts/truetype/noface/VcrEas-rX3K.ttf`

### Services to Enable/Disable

**Enable:**
```bash
sudo systemctl enable NetworkManager
sudo systemctl enable NetworkManager-wait-online
sudo systemctl enable avahi-daemon
sudo systemctl enable lightdm
sudo systemctl enable udisks2
sudo systemctl enable no_face_core.service
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
```

**Disable:**
```bash
sudo systemctl disable dhcpcd
sudo systemctl disable dnsmasq
sudo systemctl mask hostapd
sudo systemctl disable bluetooth  # Optional
```

### Environment Variables (Systemd Service)

```bash
DISPLAY=:0
XAUTHORITY=/home/noface/.Xauthority
PULSE_SERVER=unix:/run/user/1000/pulse/native
XDG_RUNTIME_DIR=/run/user/1000
```

---

## Hardware Connection Diagram

```
┌─────────────────────────────────────────────────────────┐
│ Raspberry Pi 4/5                                        │
│                                                         │
│  ┌─────────┐  eth0  ┌──────────────────┐              │
│  │ Onboard ├────────┤ GL.iNet Router   │              │
│  │ Ethernet│        │ 192.168.8.1/24   │              │
│  └─────────┘        │ (Isolated LAN)   │              │
│                     └──────────────────┘              │
│                              │                         │
│  ┌─────────┐  eth1       Visitor WiFi                 │
│  │USB-Ether├────────┐   (noface.local)                │
│  │ Adapter │        │                                 │
│  └─────────┘        │                                 │
│                     │                                 │
│              Home Router                              │
│           (Internet Access)                           │
│                     │                                 │
│  ┌─────────┐        │                                 │
│  │USB Flash├────────┤                                 │
│  │  Drive  │   USB  │                                 │
│  └─────────┘        │                                 │
│  Videos/            │                                 │
│  staticVideos/      │                                 │
│  interrupterVideo/  │                                 │
│                     │                                 │
│  ┌─────────┐        │                                 │
│  │USB Camera├───────┤                                 │
│  └─────────┘   USB  │                                 │
│  /dev/video0        │                                 │
│                     │                                 │
│  ┌─────────┐        │                                 │
│  │ Display ├────────┤                                 │
│  └─────────┘  HDMI  │                                 │
│                     │                                 │
│  ┌─────────┐        │                                 │
│  │ Rotary  ├────────┤                                 │
│  │ Encoder │  GPIO  │                                 │
│  └─────────┘ 17,18,27                                │
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

## Security Considerations

### Network Isolation

- **Production network (eth0)** is isolated (no Internet)
- GL.iNet router should have:
  - WAN port disconnected
  - Firewall enabled
  - Admin password changed from default
  - WiFi password set

### Service Permissions

- Service runs as user `noface` (not root)
- Uses `AmbientCapabilities=CAP_NET_BIND_SERVICE` for port 80
- No sudo required for service operation

### SSH Access

- SSH enabled for administration
- Key-based authentication recommended (not configured in base image)
- Accessible via both networks:
  - Production: `ssh noface@192.168.8.2`
  - Development: `ssh noface@noface.local` (if eth1 connected)

### Updates

- Development network (eth1) provides Internet for:
  - `apt update && apt upgrade`
  - `pip install --upgrade`
  - Git operations
- Production network (eth0) never has Internet access

---

## Additional Notes

### USB Drive Format

**Recommended:** FAT32 (exFAT also works)
- Maximum file size: 4GB (FAT32 limitation)
- Compatible with all systems
- Auto-mounts with correct permissions

**Not Recommended:** NTFS
- Requires `ntfs-3g` package
- May have permission issues

### Video Format Compatibility

**VLC Supported Formats:**
- MP4 (H.264/H.265)
- AVI
- MKV
- MOV
- Any format VLC can play

**Recommended:**
- MP4 with H.264 codec (best compatibility)
- Resolution: 1920x1080 or lower (Pi 4/5 handles this well)
- Aspect ratio: 4:3 (auto-cropped by VLC)

### Performance Tuning

**For better performance:**
- Use wired Ethernet (eth0/eth1), not WiFi
- Use USB 3.0 flash drive (faster read speeds)
- Keep video files under 2GB each
- Disable unused services (Bluetooth, etc.)

**Expected Resource Usage:**
- CPU: 20-30% (1-2 cores) during playback
- RAM: 500MB-1GB (out of 4GB/8GB)
- GPU: Hardware-accelerated decoding (minimal CPU)

### GL.iNet Router Configuration

**Router Mode Setup:**
1. Access router admin: http://192.168.8.1
2. Change admin password
3. Set WiFi SSID and password
4. Configure LAN subnet: 192.168.8.1/24
5. Enable DHCP: 192.168.8.100 - 192.168.8.200
6. Reserve 192.168.8.2 for Pi (or use static on Pi)
7. WAN port: Leave disconnected (isolated network)

**Note:** Do NOT use Access Point Mode - use Router Mode for proper DHCP/DNS services.

---

**End of Deployment Guide**

**For more information, see:**
- `.github/README.md` - Documentation index
- `.github/NETWORKING.md` - Detailed network architecture
- `.github/TECHNICAL_LESSONS.md` - Implementation patterns
- `.github/copilot-instructions.md` - Coding standards
