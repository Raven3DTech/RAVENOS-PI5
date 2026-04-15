# KlipperPi Changelog

## v1.0.0 — Initial Release

### Components
- Klipper (Klipper3d/klipper @ master)
- Moonraker (Arksine/moonraker @ master)
- Mainsail (mainsail-crew/mainsail @ latest stable)
- Configurator (Rat-OS/RatOS-configurator @ v2.1.x)

### Base OS
- Raspberry Pi OS Lite Bookworm 64-bit (arm64)

### Targets
- Raspberry Pi 5 ✅
- Raspberry Pi 4 ✅

### Features
- Full Klipper + Moonraker + Mainsail stack
- Configurator accessible from Mainsail sidebar
- Board detection and automatic firmware flashing
- Config generation wizard
- Automatic filesystem expansion on first boot
- Unique hostname generation per device (klipperpi-XXXX)
- mDNS via Avahi (klipperpi.local)
- Update Manager integration for all components
- STM32 / AVR / RP2040 flashing tools pre-installed
- udev rules for USB flashing devices
- PolicyKit rules for Moonraker power/service management
