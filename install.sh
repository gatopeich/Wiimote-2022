#!/bin/bash
# Wiimote-2022 Driver Installation Script
# Detects distribution and provides appropriate installation instructions

set -e

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

print_info "Wiimote-2022 Driver Installation Script"
echo ""

# Detect distribution
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_PRETTY=$PRETTY_NAME
else
    print_error "Cannot detect distribution"
    exit 1
fi

print_info "Detected: $DISTRO_PRETTY"
echo ""

# Check for dkms.conf
if [[ ! -f "dkms.conf" ]]; then
    print_error "dkms.conf not found in current directory"
    print_error "Please run this script from the Wiimote-2022 repository directory"
    exit 1
fi

# Distribution-specific installation
case "$DISTRO" in
    arch|manjaro|endeavouros)
        print_info "Arch-based distribution detected"
        print_info "Please use the specialized installation script:"
        echo ""
        echo -e "  ${GREEN}sudo ./install-arch.sh${NC}"
        echo ""
        print_info "Or see INSTALL-ARCH.md for manual installation instructions"
        exit 0
        ;;
    
    ubuntu|debian|linuxmint|pop)
        print_info "Debian-based distribution detected"
        print_info "Installing dependencies..."
        
        apt-get update
        apt-get install -y dkms linux-headers-$(uname -r) build-essential
        
        ;;
    
    fedora|rhel|centos|rocky|almalinux)
        print_info "RedHat-based distribution detected"
        print_info "Installing dependencies..."
        
        if command -v dnf &> /dev/null; then
            dnf install -y dkms kernel-devel kernel-headers gcc make
        else
            yum install -y dkms kernel-devel kernel-headers gcc make
        fi
        ;;
    
    opensuse*|sles)
        print_info "SUSE-based distribution detected"
        print_info "Installing dependencies..."
        
        zypper install -y dkms kernel-devel kernel-default-devel gcc make
        ;;
    
    *)
        print_warning "Unknown distribution: $DISTRO"
        print_info "Attempting generic installation..."
        print_warning "You may need to manually install: dkms, kernel-headers, build-essential"
        ;;
esac

# Verify kernel headers
KERNEL_VERSION=$(uname -r)
if [[ ! -d "/lib/modules/$KERNEL_VERSION/build" ]]; then
    print_error "Kernel headers not found at /lib/modules/$KERNEL_VERSION/build"
    print_error "Please install kernel headers for your kernel version"
    exit 1
fi

print_success "Kernel headers found"

# Remove old installation if exists
if dkms status | grep -q "Wiimote-2022"; then
    print_info "Removing previous installation..."
    
    # Unload module if loaded
    if lsmod | grep -q "hid_wiimote"; then
        print_info "Unloading old module..."
        modprobe -r hid-wiimote 2>/dev/null || true
    fi
    
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
if ! dkms status | grep -q "Wiimote-2022.*installed"; then
    print_error "DKMS installation verification failed"
    exit 1
fi

print_success "DKMS installation verified"

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
fi

# Print success message
echo ""
print_success "═══════════════════════════════════════════════════════════"
print_success "  Wiimote-2022 Driver Installation Complete!"
print_success "═══════════════════════════════════════════════════════════"
echo ""
print_info "Next steps:"
echo "  1. Put your Wiimote in discovery mode (press sync button or 1+2)"
echo "  2. Connect via Bluetooth using bluetoothctl"
echo ""
print_info "For detailed connection instructions, see README.md"
print_info "For troubleshooting, see TROUBLESHOOTING.md"
echo ""
print_info "To uninstall:"
echo "  ${YELLOW}sudo modprobe -r hid-wiimote${NC}"
echo "  ${YELLOW}sudo dkms remove Wiimote-2022/20.22 --all${NC}"
echo ""
