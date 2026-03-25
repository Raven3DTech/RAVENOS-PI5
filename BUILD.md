# KlipperPi — Build Guide

This document covers the full build process, troubleshooting, and how to
customise the image.

---

## Prerequisites

### Operating System
Build must be done on a **Linux** machine (native or VM).
- Ubuntu 22.04 LTS is recommended.
- WSL2 on Windows works but is slower.
- macOS is **not** supported for building (no QEMU chroot support).

### Required packages
```bash
sudo apt-get update
sudo apt-get install -y \
    gawk make build-essential util-linux \
    qemu-user-static qemu-system-arm \
    git p7zip-full python3 curl unzip wget
```

### Disk space
Allow at least **8 GB free** — the base image is ~2 GB expanded and the
build workspace needs room to work.

---

## Step-by-Step Build

### 1. Clone both repos side by side

```
~/
├── CustomPiOS/     ← https://github.com/guysoft/CustomPiOS
└── KlipperPi/      ← this repo
```

```bash
cd ~
git clone https://github.com/guysoft/CustomPiOS.git
git clone https://github.com/YOUR_USERNAME/KlipperPi.git
```

### 2. Download the base Raspberry Pi OS image

```bash
cd ~/KlipperPi
make download-image
```

Or manually:
```bash
mkdir -p src/image
wget -c https://downloads.raspberrypi.org/raspios_lite_arm64_latest \
     -O src/image/raspios_lite_arm64_latest.img.xz
```

> ⚠️ Use the **Lite** (no desktop) **arm64** image for Pi 5.  
> The same image also works on Pi 4.

### 3. Update CustomPiOS paths

This links CustomPiOS scripts into the KlipperPi source tree:

```bash
cd ~/KlipperPi
make update-paths
```

Or manually:
```bash
cd src
../../CustomPiOS/src/update-custompios-paths
```

### 4. (Optional) Customise the config

Edit `src/config` to change:
- `BASE_HOSTNAME` — default `klipperpi`
- `BASE_TIMEZONE` — default `Australia/Sydney`
- `BASE_LOCALE` — default `en_AU.UTF-8`

### 5. Build

```bash
cd ~/KlipperPi
make build
```

This takes **30–90 minutes** depending on your internet speed and machine.
The build downloads packages inside the chroot.

The finished image will be at:
```
src/workspace/KlipperPi.img
```

---

## Flashing

### Raspberry Pi Imager (Recommended)
1. Open Raspberry Pi Imager
2. Choose OS → Use Custom → select `KlipperPi.img`
3. Choose your SD card or NVMe
4. Write

### dd (Linux)
```bash
sudo dd if=src/workspace/KlipperPi.img of=/dev/sdX bs=4M status=progress
sync
```

Replace `/dev/sdX` with your actual device (check with `lsblk`).

---

## First Boot

1. Insert the media into your Pi 5
2. Connect to your network via **Ethernet** (WiFi can be set up afterward)
3. Wait ~2 minutes for first-boot setup to complete
4. Browse to `http://klipperpi.local` — Mainsail loads
5. Click **KlipperPi Configurator** in the left sidebar
6. Follow the wizard to detect and flash your 3D printer board

> **Tip:** If `klipperpi.local` doesn't resolve, try the IP address shown
> in your router's DHCP table, or connect a monitor to the Pi.

---

## WiFi Setup

WiFi can be configured after first boot via SSH:

```bash
ssh pi@klipperpi.local
# password: raspberry

sudo nmtui
# Select "Activate a connection" → choose your network → enter password
```

Or use `raspi-config`:
```bash
sudo raspi-config
# → System Options → Wireless LAN
```

---

## Default Credentials

| Service | URL | User | Password |
|---|---|---|---|
| SSH | `ssh pi@klipperpi.local` | `pi` | `raspberry` |
| Mainsail | `http://klipperpi.local` | — | — |
| Configurator | `http://klipperpi.local:3000` | — | — |

> **Security:** Change the default SSH password immediately:
> ```bash
> passwd pi
> ```

---

## Service Management

```bash
# Check status of all KlipperPi services
systemctl status klipper moonraker ratos-configurator nginx

# Restart a service
sudo systemctl restart klipper
sudo systemctl restart moonraker
sudo systemctl restart ratos-configurator

# View live logs
journalctl -fu klipper
journalctl -fu moonraker
journalctl -fu ratos-configurator

# First boot log
cat /var/log/klipperpi-firstboot.log
```

---

## Updating Components

All components update through Mainsail's built-in Update Manager:

1. Open Mainsail → `http://klipperpi.local`
2. Go to **Settings → Update Manager**
3. Click **Check for updates**
4. Update each component individually

---

## Troubleshooting

### Mainsail not loading
```bash
sudo systemctl status nginx
sudo nginx -t
sudo journalctl -fu nginx
```

### Moonraker not connecting
```bash
sudo systemctl status moonraker
journalctl -fu moonraker
cat ~/printer_data/logs/moonraker.log
```

### Klipper not starting
```bash
sudo systemctl status klipper
cat ~/printer_data/logs/klippy.log
```
> Klipper will fail to start if `printer.cfg` has no `[mcu]` section.
> This is expected until you run the Configurator wizard.

### Configurator not appearing in sidebar
```bash
sudo systemctl status ratos-configurator
journalctl -fu ratos-configurator
```
Check Moonraker has loaded the panel config:
```bash
curl http://localhost:7125/server/info | python3 -m json.tool | grep -i panel
```

### Configurator can't flash board
Check USB connection, then verify sudo rules are in place:
```bash
sudo -l -U pi | grep dfu
sudo -l -U pi | grep flash
```

---

## Module System

Each directory under `src/modules/` is a CustomPiOS module:

```
src/modules/<name>/
    config              ← env vars sourced by start_chroot_script
    start_chroot_script ← install script run inside the image chroot
    filesystem/         ← files copied into the image filesystem
```

To add a new module (e.g., KlipperScreen):
1. Create `src/modules/klipperscreen/`
2. Add `config` and `start_chroot_script`
3. Add `klipperscreen` to `MODULES=` in `src/config`
4. Rebuild

---

## Architecture Reference

```
Pi 5 (Bookworm 64-bit arm64)
├── systemd services
│   ├── klipper.service          :  klippy.py → /tmp/klippy_uds
│   ├── moonraker.service        :  moonraker.py → :7125
│   ├── nginx.service            :  → :80 (Mainsail) + proxy :7125
│   ├── ratos-configurator.service: next start → :3000
│   ├── avahi-daemon.service     :  mDNS → klipperpi.local
│   └── klipperpi-firstboot.service (runs once, then disables itself)
│
├── /home/pi/
│   ├── klipper/                 Klipper source + klippy-env/
│   ├── moonraker/               Moonraker source + moonraker-env/
│   ├── mainsail/                Mainsail web app (symlinked to /var/www/mainsail)
│   ├── ratos-configurator/      Next.js app
│   ├── scripts/                 firstboot + helper scripts
│   └── printer_data/
│       ├── config/              printer.cfg, moonraker.conf, RatOS/
│       ├── logs/                klippy.log, moonraker.log
│       ├── gcodes/              uploaded gcode files
│       └── comms/               unix sockets
│
└── /etc/
    ├── nginx/sites-enabled/mainsail
    ├── systemd/system/*.service
    ├── sudoers.d/klipperpi-flash
    └── udev/rules.d/49-klipperpi.rules
```
