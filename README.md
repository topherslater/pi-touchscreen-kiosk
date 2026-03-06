# Raspberry Pi Touchscreen Kiosk Setup

Set up and calibrate a Samsung Hub touchscreen display on a Raspberry Pi 5 running Raspberry Pi OS Bookworm (Wayland/labwc) for use as a portrait-mode kiosk (e.g., Home Assistant dashboard).

## Hardware

- Raspberry Pi 5
- ILI251x (or ILI210x) I2C/USB touchscreen
- 1920×1080 HDMI display, mounted in portrait orientation (270° rotation)

## What's Included

| File | Description |
|------|-------------|
| [`setup-touchscreen.sh`](setup-touchscreen.sh) | Bash script to configure everything from scratch |
| [`touchscreen-calibration-wayland-pi.md`](touchscreen-calibration-wayland-pi.md) | Detailed guide covering the full calibration process |

## Quick Start

```bash
# Clone the repo
git clone https://github.com/topherslater/pi-touchscreen-kiosk.git
cd pi-touchscreen-kiosk

# Edit the Home Assistant URL if needed
nano setup-touchscreen.sh  # change HASS_URL at the top

# Run the setup
sudo bash setup-touchscreen.sh

# Reboot
sudo reboot
```

## What the Script Does

1. Adds the `ilitek251x` touchscreen overlay to `/boot/firmware/config.txt`
2. Creates a udev rule with a calibration matrix for 270° touch rotation
3. Configures labwc (Wayland compositor) for Chromium kiosk mode
4. Sets up wayfire.ini with display rotation via `wlr-randr`
5. Installs required packages (labwc, chromium, wlr-randr, etc.)
6. Enables LightDM display manager

## Manual Calibration

If your touchscreen's coordinate range doesn't match the defaults, you'll need to manually calibrate. The [detailed guide](touchscreen-calibration-wayland-pi.md) covers:

- Capturing raw touch coordinates (not post-calibration!)
- Setting the correct ABS range via hwdb
- Choosing the right rotation matrix
- Troubleshooting common issues

## Key Lessons

- **Don't use `display_rotate` in config.txt with Wayfire/labwc** — use `wlr-randr` instead
- **`libinput debug-events` shows post-calibration values** — use raw evdev reads for calibration
- **Don't mix compositor touch transforms with calibration matrices** — use one or the other
- **Touch panels often report a much larger range than they physically use** — hwdb range overrides fix this

## License

MIT
