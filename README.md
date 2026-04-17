# R3DTOS PI5

**R3DTOS PI5** is a **port of the RatOS v2.1.x** printer software stack to **Raspberry Pi OS Lite arm64** for **Raspberry Pi 5** (Pi 4 is supported too). It is **not** the upstream RatOS CB1 image: it reuses **RatOS-configuration**, **RatOS Configurator**, and RatOS-derived modules (hotspot, tooling) where they work on Pi OS, with Pi‑5 / Bookworm adjustments documented in **BUILD.md**. **RatOS** and **RatRig** remain the upstream source of truth for configuration patterns; this image exists to run that ecosystem on official Raspberry Pi hardware.

Built with **CustomPiOS**.

Includes:
- **Klipper** — 3D printer firmware
- **Moonraker** — Klipper API server
- **Mainsail** — Web UI for Klipper
- **Configurator** — RatOS Configurator: board configuration, flashing and provisioning wizard

Targets **Raspberry Pi 5** running **Bookworm 64-bit**, but is compatible with Pi 4 as well.

**Monorepo / Windows / clone layout:** see **[`docs/WORKSPACE.md`](docs/WORKSPACE.md)** (R3DTech Configurator sibling projects, `CustomPiOS` path, optional Windows junction, CI vs local build).

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
git clone https://github.com/Raven3DTech/R3DTOS-PI5.git R3DTOS-PI5
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

## First Boot (aligned with [RatOS 2.1.x installation](https://os.ratrig.com/docs/installation/))

RatOS ships **Klipper, Moonraker, Mainsail, and the Configurator** enabled together on boot. Klipper may show errors until a board is configured; **Moonraker is still expected to be running** so Mainsail and most Configurator API calls work. The documented *user* order is network first, then updates in Mainsail, then the rest of the hardware wizard.

1. Insert the SD card / NVMe into your Pi 5 and power on.
2. **Wi‑Fi only (no Ethernet):** wait for the fallback hotspot **SSID `r3dtospi5`** (passphrase **`raspberry`**), join it, then open the Configurator setup at **`http://192.168.50.1/configure`** to set **Wi‑Fi and hostname** (same URL pattern as stock RatOS: `http://RatOS.local/configure` / `http://192.168.50.1/configure`).  
   **Ethernet:** you can skip the hotspot and go straight to **`http://r3dtospi5.local/configure`** (hostname may become **`r3dtospi5-XXXX`** after first boot — check console or router).
3. Complete that first wizard step; upstream then has you **reboot** onto your LAN before continuing.
4. Open **Mainsail** at **`http://<hostname>.local`** or **`http://<hostname>.local/config`** (port 80; `/config` redirects to `/`, matching RatOS install docs). Use **Update Manager** to refresh RatOS-related components before advancing the wizard (see upstream “Do NOT continue … before updating the software!”).
5. Open **Configurator** again (sidebar link or **`http://<hostname>.local/configure`**) and continue through **board detection / flash** and the hardware wizard.

**How it is served:** nginx on port **80** reverse-proxies **`/configure/*`** to Next.js on **127.0.0.1:3000** (RatOS-configurator **`basePath: '/configure'`**). You can still open **`http://<host>:3000/configure`** directly if nginx is down.

**Fallback hotspot:** **`http://192.168.50.1`** — Mainsail; **`http://192.168.50.1/configure`** — Configurator (first‑run Wi‑Fi/hostname).

---

## Default Credentials

| Item | Value |
|---|---|
| Hostname | `r3dtospi5.local` (may become `r3dtospi5-XXXX.local` after first boot) |
| SSH user | `pi` |
| SSH password | `raspberry` *(change on first login)* |
| Mainsail URL | `http://r3dtospi5.local` |
| Configurator URL | `http://r3dtospi5.local/configure` (direct Next: `:3000/configure`) |

---

## Architecture

```
Browser
  └── http://r3dtospi5.local              → Mainsail (nginx → /var/www/mainsail)
  └── http://r3dtospi5.local/configure    → RatOS Configurator (nginx → Next.js :3000, `basePath` /configure)

Mainsail  ──────────────────────────► Moonraker API (:7125)
Configurator (browser) ─────────────► Moonraker via nginx :80 (/server, /api, …) → :7125
Configurator (Node server) ─────────► Moonraker loopback :7125 (MOONRAKER_API_URL)
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
