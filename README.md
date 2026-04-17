# R3DTOS PI5

**R3DTOS PI5** is a **port of the RatOS v2.1.x** printer software stack to **Raspberry Pi OS Lite arm64** for **Raspberry Pi 5** (Pi 4 is supported too). It is **not** the upstream RatOS CB1 image: it reuses **RatOS-configuration**, **RatOS Configurator**, and RatOS-derived modules (hotspot, tooling) where they work on Pi OS, with Pi‑5 / Bookworm adjustments documented in **BUILD.md**. **RatOS** and **RatRig** remain the upstream source of truth for configuration patterns; this image exists to run that ecosystem on official Raspberry Pi hardware.

Built with **CustomPiOS**.

Includes:
- **Klipper** — 3D printer firmware
- **Moonraker** — Klipper API server
- **Mainsail** — Web UI for Klipper
- **Configurator** — RatOS Configurator: board configuration, flashing and provisioning wizard

Targets **Raspberry Pi 5** running **Bookworm 64-bit**, but is compatible with Pi 4 as well.

---

## Requirements

### Build Machine
- Ubuntu 22.04 LTS (or any Debian-based Linux, or WSL2 on Windows)
- At least 8GB free disk space
- Internet connection during build

### Tools
```bash
sudo apt-get install -y \
  gawk make build-essential util-linux \
  qemu-user-static qemu-system-arm \
  git p7zip-full python3 curl unzip
```

---

## Quick Start

### 1. Clone this repo and CustomPiOS

Use the folder name **`R3DTOS-PI5`** so the CustomPiOS output image is named **`R3DTOS-PI5.img`** (the name matches the parent directory of `src/`).

```bash
git clone https://github.com/YOUR_USERNAME/R3DTOS-PI5.git
git clone https://github.com/guysoft/CustomPiOS.git
```

### 2. Download the base Raspberry Pi OS image

```bash
cd R3DTOS-PI5/src/image
wget -c https://downloads.raspberrypi.org/raspios_lite_arm64_latest -O raspios_lite_arm64_latest.img.xz
```

> **Note:** Use the Bookworm Lite 64-bit image for Pi 5. For Pi 4, use the same image — it is compatible.

### 3. Update CustomPiOS paths

```bash
cd R3DTOS-PI5/src
../../CustomPiOS/src/update-custompios-paths
```

### 4. Build the image

```bash
cd R3DTOS-PI5/src
sudo modprobe loop
sudo bash -x ./build_dist
```

The finished image will be at:
```
R3DTOS-PI5/src/workspace/R3DTOS-PI5.img
```

*(If your clone folder has a different name, the `.img` filename matches that folder.)*

### 5. Flash the image

Use **Raspberry Pi Imager** (recommended) and select the `.img` file, or:

```bash
sudo dd if=R3DTOS-PI5.img of=/dev/sdX bs=4M status=progress
sync
```

---

## First Boot

1. Insert the SD card / NVMe into your Pi 5
2. Connect to your network via Ethernet (recommended for first boot)
3. Browse to `http://r3dtospi5.local` — Mainsail loads (after first boot, hostname may be `r3dtospi5-XXXX` — check the Pi’s console or router)
4. Click **Configurator** in the left sidebar
5. Follow the wizard to detect your board, generate config, and flash firmware

**Fallback hotspot:** SSID **`r3dtospi5`** (default passphrase **`raspberry`**). On that network, open **`http://192.168.50.1`** for Mainsail and **`http://192.168.50.1:3000`** for the Configurator.

---

## Default Credentials

| Item | Value |
|---|---|
| Hostname | `r3dtospi5.local` (may become `r3dtospi5-XXXX.local` after first boot) |
| SSH user | `pi` |
| SSH password | `raspberry` *(change on first login)* |
| Mainsail URL | `http://r3dtospi5.local` |
| Configurator URL | `http://r3dtospi5.local:3000` |

---

## Architecture

```
Browser
  └── http://r3dtospi5.local          → Mainsail (nginx → /var/www/mainsail)
  └── http://r3dtospi5.local:3000     → Configurator (Next.js / port 3000)

Mainsail  ──────────────────────────► Moonraker API (:7125)
Configurator ───────────────────────► Moonraker API (:7125)
                                       └──► Klipper (unix socket)
                                       └──► Board flash scripts (sudo)
```

---

## Updating Components

Each component can be updated independently via Moonraker's update manager
(built into Mainsail under **Settings → Update Manager**).

---

## Modules

| Module | Source |
|---|---|
| network-support | WiFi firmware + WPA tools (NM from base Pi OS; ModemManager masked on first boot) |
| hotspot | [RatOS v2.1.x hotspot](https://github.com/Rat-OS/RatOS/tree/v2.1.x/src/modules/hotspot) — autohotspot / hostapd / dnsmasq (see **BUILD.md**) |
| Klipper | https://github.com/Klipper3d/klipper |
| Moonraker | https://github.com/Arksine/moonraker |
| Mainsail | https://github.com/mainsail-crew/mainsail |
| Configurator | https://github.com/Rat-OS/RatOS-configurator |
| RatOS-configuration | https://github.com/Rat-OS/RatOS-configuration (branch v2.1.x, path ~/printer_data/config/RatOS) |
| Crowsnest | https://github.com/mainsail-crew/crowsnest |
| Sonar | https://github.com/mainsail-crew/sonar |
| moonraker-timelapse | https://github.com/mainsail-crew/moonraker-timelapse |
| KlipperScreen | https://github.com/jordanruthe/KlipperScreen |
| dfu-util | https://gitlab.com/dfu-util/dfu-util (RatOS-style source build) |

---

## License

MIT — This build system is open source. Klipper, Moonraker, Mainsail and the RatOS
projects retain their respective licenses.
