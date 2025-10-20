# Installation Guide for Arch Linux, Manjaro, and AUR-based Distributions

This guide provides step-by-step instructions for installing the Wiimote-2022 driver on Arch-based distributions (Arch Linux, Manjaro, EndeavourOS, etc.).

## Prerequisites

Before installing the driver, you need to have the following packages installed:

### Required Packages

```bash
# Update your system first
sudo pacman -Syu

# Install required packages
sudo pacman -S --needed base-devel dkms linux-headers
```

**Note:** 
- `base-devel` includes essential build tools (gcc, make, etc.)
- `dkms` is the Dynamic Kernel Module Support framework
- `linux-headers` must match your kernel version

### Check Your Kernel Version

To ensure you have the correct kernel headers:

```bash
uname -r
```

If you're using a specific kernel (e.g., `linux-lts`, `linux-zen`), install the matching headers:

```bash
# For LTS kernel
sudo pacman -S linux-lts-headers

# For Zen kernel
sudo pacman -S linux-zen-headers
```

## Installation Methods

### Method 1: Automated Installation (Recommended)

Use the provided installation script:

```bash
cd /path/to/Wiimote-2022
chmod +x install-arch.sh
sudo ./install-arch.sh
```

The script will:
1. Check for required dependencies
2. Install missing packages
3. Install the driver using DKMS
4. Load the module with gamepad support enabled

### Method 2: Manual Installation

#### Step 1: Install Dependencies

```bash
sudo pacman -S --needed base-devel dkms linux-headers
```

#### Step 2: Install with DKMS

From the repository directory:

```bash
sudo dkms install .
```

This will:
- Build the kernel module for your current kernel
- Install it to `/lib/modules/$(uname -r)/updates/`
- Register it with DKMS for automatic rebuilds on kernel updates

#### Step 3: Load the Module

After DKMS installation, the module is **not** in the current directory. Load it using modprobe:

```bash
# Load dependencies first
sudo modprobe ff-memless

# Remove old module if loaded
sudo modprobe -r hid-wiimote 2>/dev/null || true

# Load the new module with gamepad support
sudo modprobe hid-wiimote gamepad=1
```

**Important:** After DKMS installation, do NOT use `insmod hid-wiimote.ko` from the source directory! The module is installed system-wide and should be loaded with `modprobe`.

## Configuration

### Enable Gamepad Mode

To use the Wiimote as a gamepad (recommended for gaming):

```bash
sudo modprobe hid-wiimote gamepad=1
```

### Load Module Automatically on Boot

To load the module with gamepad support on every boot:

```bash
# Create module configuration
echo "options hid-wiimote gamepad=1" | sudo tee /etc/modprobe.d/hid-wiimote.conf

# Add module to load at boot
echo "hid-wiimote" | sudo tee /etc/modules-load.d/hid-wiimote.conf
```

## Connecting Your Wiimote

### Step 1: Put Wiimote in Discovery Mode

Press the red sync button inside the battery compartment or press buttons 1+2 simultaneously.

### Step 2: Connect via Bluetooth

```bash
bluetoothctl
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# default-agent
[bluetooth]# scan on
```

Wait for your Wiimote to appear (it will show as "Nintendo RVL-CNT-01"), then:

```bash
[bluetooth]# pair XX:XX:XX:XX:XX:XX
[bluetooth]# connect XX:XX:XX:XX:XX:XX
[bluetooth]# trust XX:XX:XX:XX:XX:XX
[bluetooth]# exit
```

Replace `XX:XX:XX:XX:XX:XX` with your Wiimote's MAC address.

### Step 3: Verify Connection

Check that the gamepad device was created:

```bash
# List input devices
ls -l /dev/input/by-id/*Wiimote*

# Test with evtest (install with: sudo pacman -S evtest)
sudo evtest
```

Select your Wiimote device and test the buttons and joystick.

## Troubleshooting

### Issue: "could not load module hid-wiimote.ko: No such file or directory"

**Cause:** You're trying to use `insmod` with a local .ko file after DKMS installation.

**Solution:** Use `modprobe` instead:
```bash
sudo modprobe hid-wiimote gamepad=1
```

### Issue: Module not found with modprobe

**Check if DKMS installation succeeded:**
```bash
dkms status
```

You should see:
```
Wiimote-2022/20.22, <kernel-version>, x86_64: installed
```

**Find the installed module:**
```bash
find /lib/modules/$(uname -r) -name "hid-wiimote.ko*"
```

**If module is not found, rebuild it:**
```bash
sudo dkms remove Wiimote-2022/20.22 --all
sudo dkms install .
```

### Issue: Wiimote connects but all four lights keep flashing

**Causes:**
1. Module not loaded with gamepad=1 parameter
2. Module loaded before Wiimote connection

**Solution:**
```bash
# Disconnect Wiimote first
# Then reload module
sudo modprobe -r hid-wiimote
sudo modprobe hid-wiimote gamepad=1
# Now reconnect Wiimote
```

### Issue: Steam doesn't detect the controller

**Verify gamepad is detected:**
```bash
cat /proc/bus/input/devices | grep -A 5 "Wiimote"
```

Look for a device with handlers including `js0` (joystick) or `event*`.

**Check Steam controller settings:**
1. Open Steam
2. Go to Settings → Controller → General Controller Settings
3. Enable "Generic Gamepad Configuration Support"

### Issue: Module fails to build

**Check kernel headers are installed:**
```bash
ls /lib/modules/$(uname -r)/build
```

If this directory doesn't exist, install headers:
```bash
sudo pacman -S linux-headers
# Or for specific kernel: linux-lts-headers, linux-zen-headers, etc.
```

**Check for compilation errors:**
```bash
sudo dkms install . -k $(uname -r)
```

### Issue: Module doesn't load after kernel update

**DKMS should automatically rebuild, but if it doesn't:**
```bash
# Check DKMS status
dkms status

# Rebuild for new kernel
sudo dkms install Wiimote-2022/20.22 -k $(uname -r)
```

## Uninstallation

To remove the driver:

```bash
# Unload module
sudo modprobe -r hid-wiimote

# Remove from DKMS
sudo dkms remove Wiimote-2022/20.22 --all

# Remove configuration files (optional)
sudo rm -f /etc/modprobe.d/hid-wiimote.conf
sudo rm -f /etc/modules-load.d/hid-wiimote.conf
```

## Additional Resources

- [Linux Gamepad Specification](https://www.kernel.org/doc/html/latest/input/gamepad.html)
- [DKMS Documentation](https://github.com/dell/dkms)
- [Arch Wiki - Kernel modules](https://wiki.archlinux.org/title/Kernel_module)
- [xwiimote project](https://github.com/xwiimote/xwiimote)

## Getting Help

If you encounter issues not covered here:

1. Check the main [README.md](README.md) for general driver information
2. Review existing [GitHub Issues](https://github.com/gatopeich/Wiimote-2022/issues)
3. Create a new issue with:
   - Your kernel version (`uname -r`)
   - DKMS status output (`dkms status`)
   - Module loading errors (`dmesg | tail -50`)
   - Your distribution and version
