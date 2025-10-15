#!/bin/bash
# Wiimote-2022 Installation Script for Arch Linux, Manjaro, and AUR-based distributions
# This script automates the installation process including dependency checks

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Detect the actual user (when using sudo)
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

print_info "Wiimote-2022 Driver Installation Script for Arch-based Distributions"
echo ""

# Check if we're on an Arch-based distribution
if ! command -v pacman &> /dev/null; then
    print_error "This script is for Arch-based distributions (Arch, Manjaro, EndeavourOS, etc.)"
    print_error "pacman package manager not found."
    exit 1
fi

print_success "Detected Arch-based distribution"

# Get kernel version
KERNEL_VERSION=$(uname -r)
print_info "Current kernel: $KERNEL_VERSION"

# Check and install dependencies
print_info "Checking dependencies..."

MISSING_PACKAGES=()

# Check for base-devel
if ! pacman -Qg base-devel &> /dev/null; then
    MISSING_PACKAGES+=("base-devel")
fi

# Check for DKMS
if ! pacman -Q dkms &> /dev/null; then
    MISSING_PACKAGES+=("dkms")
fi

# Check for kernel headers
KERNEL_PACKAGE=$(pacman -Qo "/lib/modules/$KERNEL_VERSION/build" 2>/dev/null | awk '{print $5}' || echo "")

if [[ -z "$KERNEL_PACKAGE" ]] || [[ ! -d "/lib/modules/$KERNEL_VERSION/build" ]]; then
    # Detect which kernel is in use
    if [[ $KERNEL_VERSION == *"-lts"* ]]; then
        MISSING_PACKAGES+=("linux-lts-headers")
    elif [[ $KERNEL_VERSION == *"-zen"* ]]; then
        MISSING_PACKAGES+=("linux-zen-headers")
    elif [[ $KERNEL_VERSION == *"-hardened"* ]]; then
        MISSING_PACKAGES+=("linux-hardened-headers")
    else
        MISSING_PACKAGES+=("linux-headers")
    fi
fi

# Install missing packages
if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
    print_warning "Missing packages: ${MISSING_PACKAGES[*]}"
    print_info "Installing missing packages..."
    
    if pacman -S --needed --noconfirm "${MISSING_PACKAGES[@]}"; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
else
    print_success "All dependencies are already installed"
fi

# Verify kernel headers are available
if [[ ! -d "/lib/modules/$KERNEL_VERSION/build" ]]; then
    print_error "Kernel headers not found at /lib/modules/$KERNEL_VERSION/build"
    print_error "Please ensure the correct kernel headers package is installed"
    exit 1
fi

print_success "Kernel headers found"

# Check if dkms.conf exists
if [[ ! -f "dkms.conf" ]]; then
    print_error "dkms.conf not found in current directory"
    print_error "Please run this script from the Wiimote-2022 repository directory"
    exit 1
fi

# Remove old installation if exists
if dkms status | grep -q "Wiimote-2022"; then
    print_info "Removing previous installation..."
    
    # Unload module if loaded
    if lsmod | grep -q "hid_wiimote"; then
        print_info "Unloading old module..."
        modprobe -r hid-wiimote 2>/dev/null || true
    fi
    
    # Remove from DKMS
    dkms remove Wiimote-2022/20.22 --all 2>/dev/null || true
    print_success "Previous installation removed"
fi

# Install with DKMS
print_info "Installing driver with DKMS..."

if dkms install .; then
    print_success "Driver installed successfully with DKMS"
else
    print_error "DKMS installation failed"
    print_info "Check dmesg for details: sudo dmesg | tail -50"
    exit 1
fi

# Verify installation
print_info "Verifying installation..."

if dkms status | grep -q "Wiimote-2022.*installed"; then
    print_success "DKMS reports driver is installed"
else
    print_error "DKMS installation verification failed"
    exit 1
fi

# Find the installed module
MODULE_PATH=$(find "/lib/modules/$KERNEL_VERSION" -name "hid-wiimote.ko*" 2>/dev/null | head -n 1)

if [[ -n "$MODULE_PATH" ]]; then
    print_success "Module found at: $MODULE_PATH"
else
    print_warning "Module file not found, but DKMS reports success"
fi

# Load the module
print_info "Loading module with gamepad support..."

# Load ff-memless dependency
modprobe ff-memless 2>/dev/null || true

# Unload old module if loaded
modprobe -r hid-wiimote 2>/dev/null || true

# Load new module with gamepad=1
if modprobe hid-wiimote gamepad=1; then
    print_success "Module loaded successfully with gamepad support"
else
    print_error "Failed to load module"
    print_info "Check dmesg for details: sudo dmesg | tail -50"
    exit 1
fi

# Verify module is loaded
if lsmod | grep -q "hid_wiimote"; then
    print_success "Module is active"
else
    print_error "Module not found in lsmod output"
    exit 1
fi

# Ask about automatic loading on boot
echo ""
print_info "Would you like to configure the module to load automatically on boot? [y/N]"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_info "Configuring automatic module loading..."
    
    # Create modprobe configuration
    echo "options hid-wiimote gamepad=1" > /etc/modprobe.d/hid-wiimote.conf
    print_success "Created /etc/modprobe.d/hid-wiimote.conf"
    
    # Create modules-load configuration
    echo "hid-wiimote" > /etc/modules-load.d/hid-wiimote.conf
    print_success "Created /etc/modules-load.d/hid-wiimote.conf"
    
    print_success "Module will load automatically on boot with gamepad=1"
else
    print_info "Skipping automatic loading configuration"
    print_info "You can load the module manually with: sudo modprobe hid-wiimote gamepad=1"
fi

# Print success message and next steps
echo ""
print_success "═══════════════════════════════════════════════════════════"
print_success "  Wiimote-2022 Driver Installation Complete!"
print_success "═══════════════════════════════════════════════════════════"
echo ""
print_info "Next steps:"
echo "  1. Put your Wiimote in discovery mode (press sync button or 1+2)"
echo "  2. Connect via Bluetooth:"
echo "     ${YELLOW}bluetoothctl${NC}"
echo "     ${YELLOW}[bluetooth]# power on${NC}"
echo "     ${YELLOW}[bluetooth]# agent on${NC}"
echo "     ${YELLOW}[bluetooth]# scan on${NC}"
echo "     ${YELLOW}[bluetooth]# pair XX:XX:XX:XX:XX:XX${NC}"
echo "     ${YELLOW}[bluetooth]# connect XX:XX:XX:XX:XX:XX${NC}"
echo "     ${YELLOW}[bluetooth]# trust XX:XX:XX:XX:XX:XX${NC}"
echo ""
print_info "For troubleshooting, see: INSTALL-ARCH.md"
echo ""
print_info "To uninstall:"
echo "  ${YELLOW}sudo modprobe -r hid-wiimote${NC}"
echo "  ${YELLOW}sudo dkms remove Wiimote-2022/20.22 --all${NC}"
echo ""
