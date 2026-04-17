#!/bin/bash
# ============================================================
# R3DTOS PI5 — First Boot Setup Script
# Runs once on first boot via the r3dtospi5-firstboot service.
# Port of RatOS v2.1.x stack for Raspberry Pi OS / Pi 5 (see README).
# Handles things that cannot be done inside the chroot build:
#   - Expand filesystem
#   - Set machine hostname uniquely
#   - Generate SSH host keys
#   - Final service starts
# ============================================================
set -e

# Short hostname baked into the image (must match BASE_HOSTNAME in src/config).
DEFAULT_HOST="r3dtospi5"

LOG=/var/log/r3dtospi5-firstboot.log
exec > >(tee -a ${LOG}) 2>&1

echo "============================================"
echo "R3DTOS PI5 First Boot Setup"
echo "Started: $(date)"
echo "============================================"

# ── Wireless: ensure not soft-blocked (common on fresh images / some boards) ─
echo "[1/7] Unblocking rfkill (WiFi)..."
rfkill unblock all 2>/dev/null || true

# ModemManager can capture USB-serial devices used for printer flashing; keep it off.
systemctl stop ModemManager 2>/dev/null || true
systemctl disable ModemManager 2>/dev/null || true
systemctl mask ModemManager 2>/dev/null || true

# ── Expand root filesystem ───────────────────────────────────
echo "[2/7] Expanding filesystem..."
raspi-config --expand-rootfs || true

# ── Set unique hostname ───────────────────────────────────────
# Appends last 4 chars of Pi serial for uniqueness on networks
# with multiple R3DTOS PI5 instances.
echo "[3/7] Setting hostname..."
SERIAL=$(grep -m1 '^Serial' /proc/cpuinfo 2>/dev/null | awk '{print $3}' | tail -c 5 | head -c 4)
if [ -z "${SERIAL}" ] || [ "${SERIAL}" = "0000" ]; then
    # Pi 5 / newer kernels: full serial in device tree (hex string)
    DT_SERIAL=$(tr -d '\0' </proc/device-tree/serial-number 2>/dev/null || true)
    if [ -n "${DT_SERIAL}" ]; then
        SERIAL=$(echo -n "${DT_SERIAL}" | tail -c 4)
    fi
fi
if [ -n "${SERIAL}" ] && [ "${SERIAL}" != "0000" ]; then
    NEW_HOSTNAME="${DEFAULT_HOST}-${SERIAL}"
else
    NEW_HOSTNAME="${DEFAULT_HOST}"
fi

echo "${NEW_HOSTNAME}" > /etc/hostname
sed -i "s/${DEFAULT_HOST}/${NEW_HOSTNAME}/g" /etc/hosts

# Update moonraker.conf with new hostname
sed -i "s/${DEFAULT_HOST}.local/${NEW_HOSTNAME}.local/g" \
    /home/pi/printer_data/config/moonraker.conf

# Update RatOS configurator .env.local
sed -i "s/${DEFAULT_HOST}.local/${NEW_HOSTNAME}.local/g" \
    /home/pi/ratos-configurator/.env.local

if [ -f /home/pi/mainsail/config.json ]; then
    sed -i "s/${DEFAULT_HOST}.local/${NEW_HOSTNAME}.local/g" /home/pi/mainsail/config.json
fi

# Hotspot AP uses 192.168.50.1; dnsmasq hands clients DHCP but they need this name
# to resolve to the Pi so Mainsail (Moonraker host from config.json) connects reliably.
mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/r3dtospi5-hotspot-local.conf << EOF
# Written by r3dtospi5-firstboot — autohotspot wlan0 subnet
address=/${NEW_HOSTNAME}.local/192.168.50.1
EOF

echo "Hostname set to: ${NEW_HOSTNAME}"

# ── Regenerate SSH host keys ──────────────────────────────────
echo "[4/7] Regenerating SSH host keys..."
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure -f noninteractive openssh-server
systemctl restart ssh

# ── Set correct ownership on printer_data ────────────────────
echo "[5/7] Setting file ownership..."
chown -R pi:pi /home/pi/printer_data
chown -R pi:pi /home/pi/ratos-configurator
chown -R pi:pi /home/pi/klipper
chown -R pi:pi /home/pi/moonraker
[ -d /home/pi/mainsail ] && chown -R pi:pi /home/pi/mainsail

# ── Enable mDNS / Avahi ───────────────────────────────────────
echo "[6/7] Enabling Avahi mDNS..."
systemctl enable avahi-daemon
systemctl start avahi-daemon

# ── Start all services ────────────────────────────────────────
echo "[7/7] Starting R3DTOS PI5 services..."
systemctl daemon-reload
systemctl start klipper
sleep 3
systemctl start moonraker
sleep 3
systemctl start ratos-configurator
systemctl restart nginx

# ── Enable auto-hotspot after first boot (avoids fighting NM during initial bring-up) ─
if systemctl list-unit-files autohotspot.service 2>/dev/null | grep -q autohotspot.service; then
  echo "[post] Enabling autohotspot.service for subsequent boots..."
  systemctl enable autohotspot.service 2>/dev/null || true
  # Oneshot unit — start once now so fallback AP works without an extra reboot.
  systemctl start autohotspot.service 2>/dev/null || true
fi

# ── Disable this service so it never runs again ───────────────
systemctl disable r3dtospi5-firstboot.service

echo "============================================"
echo "R3DTOS PI5 First Boot Complete: $(date)"
echo "Access Mainsail at: http://${NEW_HOSTNAME}.local"
echo "Access Configurator at: http://${NEW_HOSTNAME}.local:3000"
echo "On fallback hotspot Wi-Fi: http://192.168.50.1 and http://192.168.50.1:3000"
echo "============================================"
