# Installation Guide for Wiimote-2022

This guide explains how to install the Wiimote-2022 driver and configure it to persist the `gamepad=1` parameter across system reboots.

## What is the gamepad parameter?

The `gamepad` parameter controls the driver's behavior:
- **gamepad=1** (recommended): Combines Wiimote and Nunchuk into a single gamepad device following the Linux Gamepad Specification
- **gamepad=0**: Uses the old driver behavior with separate devices per function

**Important:** The default in the source code is `gamepad=1`, but some systems may override this at boot. This guide ensures the parameter persists correctly.

## Quick Install Scripts

For convenience, we provide automated installation scripts:

### Ubuntu / Linux Mint (Debian-based)
```bash
sudo bash install-ubuntu.sh
```

### Arch Linux
```bash
sudo bash install-arch.sh
```

## Manual Installation

### Prerequisites

Install required packages:

**Ubuntu/Debian/Mint:**
```bash
sudo apt-get update
sudo apt-get install dkms linux-headers-$(uname -r) build-essential
```

**Arch Linux:**
```bash
sudo pacman -S dkms linux-headers base-devel
```

### Step 1: Install the Driver

#### Option A: Using DKMS (Recommended)

DKMS will automatically rebuild the module when your kernel is updated.

```bash
cd /path/to/Wiimote-2022
sudo dkms install .
```

#### Option B: Manual Build

Build and install the module manually:

```bash
cd /path/to/Wiimote-2022/src
make
sudo make install
sudo depmod -a
```

### Step 2: Make gamepad=1 Persistent

To ensure the `gamepad=1` parameter is set every time the module loads, you need to create a modprobe configuration file.

Create the file `/etc/modprobe.d/hid-wiimote.conf` with the following content:

```bash
sudo bash -c 'echo "options hid-wiimote gamepad=1" > /etc/modprobe.d/hid-wiimote.conf'
```

This ensures that whenever the `hid-wiimote` module is loaded (automatically or manually), it will use `gamepad=1`.

### Step 3: Reload the Module

Unload and reload the module to apply the new configuration:

```bash
sudo modprobe -r hid-wiimote
sudo modprobe hid-wiimote
```

### Step 4: Verify the Configuration

Check that the parameter is set correctly:

```bash
cat /sys/module/hid_wiimote/parameters/gamepad
```

This should display `Y` (for true/1).

You can also verify with:

```bash
modinfo hid-wiimote | grep "gamepad"
```

## Troubleshooting

### Module not loading automatically

If the module isn't loading automatically, you may need to add it to your modules list:

```bash
sudo bash -c 'echo "hid-wiimote" >> /etc/modules-load.d/wiimote.conf'
```

### Parameter still shows as 0 after reboot

1. Verify the configuration file exists and is correct:
   ```bash
   cat /etc/modprobe.d/hid-wiimote.conf
   ```
   It should show: `options hid-wiimote gamepad=1`

2. Check if another configuration file might be overriding it:
   ```bash
   grep -r "hid-wiimote" /etc/modprobe.d/
   ```

3. Rebuild initramfs (may be needed on some systems):
   
   **Ubuntu/Debian:**
   ```bash
   sudo update-initramfs -u
   ```
   
   **Arch Linux:**
   ```bash
   sudo mkinitcpio -P
   ```

### Checking if Wiimote is connected properly

After connecting your Wiimote via Bluetooth:

```bash
# Check if the device is recognized
lsmod | grep wiimote

# Check kernel messages
dmesg | grep -i wiimote

# List input devices
ls -l /dev/input/by-id/ | grep -i wiimote
```

### Testing the gamepad

You can test your Wiimote gamepad with:

```bash
# Install jstest if not already installed
sudo apt-get install joystick  # Ubuntu/Debian
sudo pacman -S joyutils         # Arch

# Test the gamepad
jstest /dev/input/js0
```

## Uninstallation

### If installed with DKMS:
```bash
sudo dkms remove Wiimote-2022/20.22 --all
```

### If installed manually:
```bash
sudo rm /lib/modules/$(uname -r)/extra/hid-wiimote.ko
sudo depmod -a
```

### Remove configuration:
```bash
sudo rm /etc/modprobe.d/hid-wiimote.conf
sudo rm /etc/modules-load.d/wiimote.conf  # if created
```

## Additional Resources

- [Linux Gamepad Specification](https://www.kernel.org/doc/html/latest/input/gamepad.html)
- [Linux Kernel Module Parameters](https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html)
- Main README: [README.md](README.md)

## Getting Help

If you continue to experience issues:
1. Check kernel logs: `dmesg | tail -50`
2. Verify module is loaded: `lsmod | grep wiimote`
3. Check parameter value: `cat /sys/module/hid_wiimote/parameters/gamepad`
4. Report issues on the GitHub repository with these details
