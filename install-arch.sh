#!/bin/bash
# Wiimote-2022 Installation Script for Arch Linux
# This script installs the hid-wiimote driver with gamepad=1 parameter persistent across reboots

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Wiimote-2022 Installation Script${NC}"
echo -e "${GREEN}For Arch Linux${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if dkms.conf exists
if [ ! -f "$SCRIPT_DIR/dkms.conf" ]; then
    echo -e "${RED}Error: dkms.conf not found in $SCRIPT_DIR${NC}"
    echo "Please run this script from the Wiimote-2022 directory"
    exit 1
fi

# Step 1: Install dependencies
echo -e "${YELLOW}Step 1: Installing dependencies...${NC}"
pacman -Sy --noconfirm dkms linux-headers base-devel

# Step 2: Remove old installation if exists
echo -e "${YELLOW}Step 2: Checking for previous installation...${NC}"
if dkms status | grep -q "Wiimote-2022"; then
    echo "Found previous installation, removing..."
    dkms remove Wiimote-2022/20.22 --all 2>/dev/null || true
fi

# Unload module if currently loaded
if lsmod | grep -q "hid_wiimote"; then
    echo "Unloading current hid-wiimote module..."
    modprobe -r hid-wiimote 2>/dev/null || true
fi

# Step 3: Install with DKMS
echo -e "${YELLOW}Step 3: Installing driver with DKMS...${NC}"
cd "$SCRIPT_DIR"
dkms install .

# Step 4: Configure persistent gamepad parameter
echo -e "${YELLOW}Step 4: Configuring persistent gamepad=1 parameter...${NC}"
MODPROBE_CONF="/etc/modprobe.d/hid-wiimote.conf"
echo "options hid-wiimote gamepad=1" > "$MODPROBE_CONF"
echo "Created configuration file: $MODPROBE_CONF"

# Step 5: Update initramfs
echo -e "${YELLOW}Step 5: Updating initramfs...${NC}"
mkinitcpio -P

# Step 6: Load the module
echo -e "${YELLOW}Step 6: Loading hid-wiimote module...${NC}"
modprobe hid-wiimote

# Step 7: Verify installation
echo -e "${YELLOW}Step 7: Verifying installation...${NC}"
if lsmod | grep -q "hid_wiimote"; then
    echo -e "${GREEN}✓ Module loaded successfully${NC}"
else
    echo -e "${RED}✗ Module failed to load${NC}"
    exit 1
fi

if [ -f "/sys/module/hid_wiimote/parameters/gamepad" ]; then
    GAMEPAD_VALUE=$(cat /sys/module/hid_wiimote/parameters/gamepad)
    if [ "$GAMEPAD_VALUE" = "Y" ]; then
        echo -e "${GREEN}✓ gamepad parameter is set to: $GAMEPAD_VALUE (enabled)${NC}"
    else
        echo -e "${YELLOW}⚠ gamepad parameter is: $GAMEPAD_VALUE${NC}"
        echo "This may be expected if you manually specified a different value."
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify gamepad parameter${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "The Wiimote-2022 driver is now installed with gamepad=1 as default."
echo ""
echo "Next steps:"
echo "1. Connect your Wiimote via Bluetooth"
echo "2. If you have a Nunchuk, connect it to the Wiimote"
echo "3. The device should appear as a standard gamepad (e.g., /dev/input/js0)"
echo ""
echo "To test your gamepad, you can use:"
echo "  sudo pacman -S joyutils"
echo "  jstest /dev/input/js0"
echo ""
echo "Configuration files created:"
echo "  - $MODPROBE_CONF"
echo ""
echo "For troubleshooting, see INSTALL.md"
echo ""
