#!/usr/bin/env bash
# setup-touchscreen.sh
# Recreates the touchscreen + kiosk display setup on a Raspberry Pi
# running Raspberry Pi OS (Bookworm) with labwc/Wayland on a Samsung Hub Display from a refrigerator..
#
# Hardware: ILI251x USB touchscreen on a 1920x1080 HDMI display, rotated 270°
# Purpose:  Home Assistant kiosk (portrait mode) with working touch input
#
# Run as root (or with sudo) on a fresh Pi OS install.

set -euo pipefail

HASS_URL="http://192.168.0.200:8123"
USER_HOME="/home/HHS"

echo "=== 1. /boot/firmware/config.txt ==="
# Add the ilitek251x touchscreen overlay with GPIO interrupt pin 4
# (replaces the wrong ili210x driver if present)
CONFIG="/boot/firmware/config.txt"
# Remove any stale ili210x overlay
sed -i '/dtoverlay=ili210x/d' "$CONFIG"
# Add ilitek251x if not already there
if ! grep -q 'dtoverlay=ilitek251x' "$CONFIG"; then
    cat >> "$CONFIG" <<'EOF'

# Touchscreen driver (ILI251x via I2C, interrupt on GPIO 4)
dtoverlay=ilitek251x,interrupt=4
EOF
    echo "  Added ilitek251x overlay to config.txt"
else
    echo "  ilitek251x overlay already in config.txt"
fi

echo "=== 2. udev rule: touchscreen calibration matrix ==="
# Rotates touch input 270° to match the display rotation
cat > /etc/udev/rules.d/99-touchscreen.rules <<'EOF'
ENV{ID_INPUT_TOUCHSCREEN}=="1", ENV{LIBINPUT_CALIBRATION_MATRIX}="0 1 0 -1 0 1 0 0 1"
EOF
echo "  Wrote /etc/udev/rules.d/99-touchscreen.rules"

echo "=== 3. labwc autostart (Chromium kiosk) ==="
LABWC_DIR="${USER_HOME}/.config/labwc"
mkdir -p "$LABWC_DIR"
cat > "${LABWC_DIR}/autostart" <<EOF
chromium ${HASS_URL} --kiosk --noerrdialogs --disable-infobars --no-first-run --enable-features=OverlayScrollbar --start-maximized
EOF
chown -R HHS:HHS "$LABWC_DIR"
echo "  Wrote ${LABWC_DIR}/autostart"

echo "=== 4. labwc rc.xml (input config) ==="
cat > "${LABWC_DIR}/rc.xml" <<'EOF'
<?xml version="1.0"?>
<openbox_config xmlns="http://openbox.org/3.4/rc"><libinput><device category="default"><pointerSpeed>0.000000</pointerSpeed><leftHanded>no</leftHanded></device></libinput><mouse><doubleClickTime>400</doubleClickTime></mouse><keyboard><repeatRate>25</repeatRate><repeatDelay>600</repeatDelay></keyboard></openbox_config>
EOF
chown HHS:HHS "${LABWC_DIR}/rc.xml"
echo "  Wrote ${LABWC_DIR}/rc.xml"

echo "=== 5. labwc environment (keyboard layout) ==="
cat > "${LABWC_DIR}/environment" <<'EOF'
XKB_DEFAULT_MODEL=pc101
XKB_DEFAULT_LAYOUT=us
XKB_DEFAULT_VARIANT=
XKB_DEFAULT_OPTIONS=
EOF
chown HHS:HHS "${LABWC_DIR}/environment"
echo "  Wrote ${LABWC_DIR}/environment"

echo "=== 6. wayfire.ini (display rotation + kiosk fallback) ==="
cat > "${USER_HOME}/.config/wayfire.ini" <<EOF
[core]
plugins = \\
        autostart

[autostart]
chromium = chromium-browser ${HASS_URL}/lovelace/kitchen --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized
screensaver = false
dpms = false

# Rotate HDMI output to portrait (270°)
rotate_display = WAYLAND_DISPLAY=wayland-1 wlr-randr --output HDMI-A-1 --transform 270
EOF
chown HHS:HHS "${USER_HOME}/.config/wayfire.ini"
echo "  Wrote ${USER_HOME}/.config/wayfire.ini"

echo "=== 7. Required packages ==="
apt-get update -qq
apt-get install -y --no-install-recommends \
    labwc \
    autotouch \
    wlr-randr \
    libinput-tools \
    squeekboard \
    chromium-browser \
    lightdm
echo "  Packages installed"

echo "=== 8. Enable LightDM ==="
systemctl enable lightdm
echo "  LightDM enabled"

echo ""
echo "Done! Reboot to apply: sudo reboot"
echo ""
echo "Post-reboot verification:"
echo "  - Check touch device:  libinput list-devices | grep -A5 Touch"
echo "  - Check display:       WAYLAND_DISPLAY=wayland-1 wlr-randr"
echo "  - Check calibration:   udevadm info /dev/input/event5 | grep CALIBRATION"
