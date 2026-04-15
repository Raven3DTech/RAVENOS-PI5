#!/bin/bash
# ============================================================
# KlipperPi — First Boot Setup Script
# Runs once on first boot via the klipperpi-firstboot service.
# Handles things that cannot be done inside the chroot build:
#   - Expand filesystem
#   - Set machine hostname uniquely
#   - Generate SSH host keys
#   - Final service starts
# ============================================================
set -e

LOG=/var/log/klipperpi-firstboot.log
exec > >(tee -a ${LOG}) 2>&1

echo "============================================"
echo "KlipperPi First Boot Setup"
echo "Started: $(date)"
echo "============================================"

# ── Expand root filesystem ───────────────────────────────────
echo "[1/6] Expanding filesystem..."
raspi-config --expand-rootfs || true

# ── Set unique hostname ───────────────────────────────────────
# Appends last 4 chars of Pi serial for uniqueness on networks
# with multiple KlipperPi instances.
echo "[2/6] Setting hostname..."
SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}' | tail -c 5 | head -c 4)
if [ -n "${SERIAL}" ] && [ "${SERIAL}" != "0000" ]; then
    NEW_HOSTNAME="klipperpi-${SERIAL}"
else
    NEW_HOSTNAME="klipperpi"
fi

echo "${NEW_HOSTNAME}" > /etc/hostname
sed -i "s/klipperpi/${NEW_HOSTNAME}/g" /etc/hosts

# Update moonraker.conf with new hostname
sed -i "s/klipperpi.local/${NEW_HOSTNAME}.local/g" \
    /home/pi/printer_data/config/moonraker.conf

# Update RatOS configurator .env.local
sed -i "s/klipperpi.local/${NEW_HOSTNAME}.local/g" \
    /home/pi/ratos-configurator/.env.local

echo "Hostname set to: ${NEW_HOSTNAME}"

# ── Regenerate SSH host keys ──────────────────────────────────
echo "[3/6] Regenerating SSH host keys..."
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure -f noninteractive openssh-server
systemctl restart ssh

# ── Set correct ownership on printer_data ────────────────────
echo "[4/6] Setting file ownership..."
chown -R pi:pi /home/pi/printer_data
chown -R pi:pi /home/pi/ratos-configurator
chown -R pi:pi /home/pi/klipper
chown -R pi:pi /home/pi/moonraker

# ── Enable mDNS / Avahi ───────────────────────────────────────
echo "[5/6] Enabling Avahi mDNS..."
systemctl enable avahi-daemon
systemctl start avahi-daemon

# ── Start all services ────────────────────────────────────────
echo "[6/6] Starting KlipperPi services..."
systemctl daemon-reload
systemctl start klipper
sleep 3
systemctl start moonraker
sleep 3
systemctl start ratos-configurator
systemctl restart nginx

# ── Disable this service so it never runs again ───────────────
systemctl disable klipperpi-firstboot.service

echo "============================================"
echo "KlipperPi First Boot Complete: $(date)"
echo "Access Mainsail at: http://${NEW_HOSTNAME}.local"
echo "Access Configurator at: http://${NEW_HOSTNAME}.local:3000"
echo "============================================"
