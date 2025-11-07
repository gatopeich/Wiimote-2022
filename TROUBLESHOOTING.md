# Troubleshooting Guide

This document contains solutions to common issues encountered when installing and using the Wiimote-2022 driver.

## Installation Issues

### "could not load module hid-wiimote.ko: No such file or directory"

**Symptoms:**
- After running `dkms install`, you try `sudo insmod hid-wiimote.ko gamepad=1`
- Error message: `insmod: ERROR: could not load module hid-wiimote.ko: No such file or directory`

**Root Cause:**
When DKMS installs a kernel module, it places the compiled `.ko` file in the system module directory (typically `/lib/modules/$(uname -r)/updates/`), not in your current source directory. The `insmod` command only works with a local file path.

**Solution:**
Use `modprobe` instead of `insmod` after DKMS installation:

```bash
# Correct way to load after DKMS installation:
sudo modprobe hid-wiimote gamepad=1

# NOT this (only works with manual compilation):
sudo insmod hid-wiimote.ko gamepad=1  # ❌ Wrong after DKMS install
```

**Why this works:**
- `modprobe` loads modules from the system module directory and handles dependencies automatically
- `insmod` only loads a module from a specific file path you provide

### DKMS reports "installed" but module won't load

**Check DKMS status:**
```bash
dkms status
```

Expected output:
```
Wiimote-2022/20.22, 6.x.x-xxx, x86_64: installed
```

**Find the installed module:**
```bash
find /lib/modules/$(uname -r) -name "hid-wiimote.ko*"
```

**If module is not found:**

1. Check for build errors in DKMS logs:
   ```bash
   cat /var/lib/dkms/Wiimote-2022/20.22/build/make.log
   ```

2. Remove and reinstall:
   ```bash
   sudo dkms remove Wiimote-2022/20.22 --all
   sudo dkms install /path/to/Wiimote-2022
   ```

3. Ensure kernel headers are installed (see distribution-specific instructions)

### "REMAKE_INITRD" deprecation warning

**Symptoms:**
```
Deprecated feature: REMAKE_INITRD (/var/lib/dkms/Wiimote-2022/20.22/source/dkms.conf)
```

**Impact:**
This is just a warning and does not affect functionality. The `REMAKE_INITRD=no` setting in `dkms.conf` is deprecated but still works.

**Why this exists:**
The setting prevents unnecessary regeneration of the initial RAM disk, which is not needed for this driver since it's loaded after boot.

### Module won't build - missing kernel headers

**Symptoms:**
- DKMS installation fails
- Error mentions missing header files or build directory

**Solution:**

For Arch/Manjaro:
```bash
sudo pacman -S linux-headers
# Or for specific kernels:
# sudo pacman -S linux-lts-headers
# sudo pacman -S linux-zen-headers
```

For Ubuntu/Debian:
```bash
sudo apt update
sudo apt install linux-headers-$(uname -r)
```

For Fedora/RHEL:
```bash
sudo dnf install kernel-devel kernel-headers
```

**Verify headers are installed:**
```bash
ls -l /lib/modules/$(uname -r)/build
```

## Connection Issues

### Wiimote connects but all four lights keep flashing

**Symptoms:**
- Bluetooth connection succeeds
- All four LEDs on Wiimote flash continuously
- No gamepad device appears

**Root Causes:**
1. Module loaded without `gamepad=1` parameter
2. Module was loaded before Wiimote connection
3. Wrong HID driver handling the device

**Solution:**

1. Disconnect the Wiimote (in bluetoothctl: `disconnect XX:XX:XX:XX:XX:XX`)

2. Reload the module with correct parameters:
   ```bash
   sudo modprobe -r hid-wiimote
   sudo modprobe hid-wiimote gamepad=1
   ```

3. Reconnect the Wiimote

**Verification:**
After reconnecting, only one LED should stay on, indicating the Wiimote is in gamepad mode.

### Wiimote won't enter pairing mode

**Symptoms:**
- Pressing 1+2 or sync button does nothing
- No blinking LEDs

**Solutions:**

1. **Check batteries:** Weak batteries can prevent pairing mode
   - Replace with fresh batteries
   - LEDs should blink when entering pairing mode

2. **Try the sync button:**
   - Open battery compartment
   - Press the small red button near the battery label
   - LEDs should start blinking

3. **Reset the Wiimote:**
   - Remove batteries
   - Wait 10 seconds
   - Reinsert batteries
   - Try pairing again

### Bluetooth connection fails or times out

**Check Bluetooth status:**
```bash
sudo systemctl status bluetooth
```

**Ensure Bluetooth is powered on:**
```bash
bluetoothctl
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# default-agent
```

**Scan for devices:**
```bash
[bluetooth]# scan on
```

The Wiimote should appear as "Nintendo RVL-CNT-01" or similar.

**If Wiimote doesn't appear:**
1. Ensure Wiimote is in pairing mode (LEDs blinking)
2. Move Wiimote closer to computer
3. Check for interference from other Bluetooth devices
4. Restart Bluetooth service: `sudo systemctl restart bluetooth`

### Wiimote disconnects immediately after pairing

**Solution - Trust the device:**
```bash
bluetoothctl
[bluetooth]# trust XX:XX:XX:XX:XX:XX
[bluetooth]# connect XX:XX:XX:XX:XX:XX
```

Replace `XX:XX:XX:XX:XX:XX` with your Wiimote's MAC address.

## Gamepad Detection Issues

### Steam doesn't detect the Wiimote

**Check if gamepad device exists:**
```bash
ls -l /dev/input/by-id/*Nintendo*
ls -l /dev/input/js*
```

**Enable Generic Gamepad Support in Steam:**
1. Open Steam
2. Go to Settings → Controller → General Controller Settings
3. Enable "Generic Gamepad Configuration Support"

**Verify device with evtest:**
```bash
sudo evtest
```
Select the Wiimote device and test buttons.

**If device doesn't appear:**
1. Ensure module is loaded with `gamepad=1`
2. Check module parameter: `cat /sys/module/hid_wiimote/parameters/gamepad`
   - Should return "1" or "Y"
3. Check dmesg for errors: `dmesg | grep -i wiimote`

### Game doesn't recognize controller

**For native Linux games:**
Most games using SDL2 should automatically detect the gamepad.

**Test with jstest:**
```bash
sudo pacman -S joyutils  # Arch
sudo apt install joystick  # Ubuntu
jstest /dev/input/js0
```

**For Wine/Proton games:**
Ensure Steam Input is enabled or disabled depending on the game's requirements.

### Wrong button mappings

**Check current mapping:**
```bash
evtest /dev/input/by-id/*Nintendo*
```

Press buttons and verify they match the expected layout.

**If mappings are incorrect:**
1. Ensure you're using `gamepad=1` parameter
2. Check if you have the latest version of the driver
3. Some games allow custom button remapping in their settings

## Module Loading Issues

### Module fails to load with "unknown symbol" error

**Check dmesg:**
```bash
dmesg | tail -20
```

**Common causes:**
1. Missing dependency modules
2. Kernel version mismatch

**Solution:**
```bash
# Load dependency
sudo modprobe ff-memless

# Try loading again
sudo modprobe hid-wiimote gamepad=1
```

### Module loads but doesn't work after kernel update

**DKMS should auto-rebuild, but if it doesn't:**

```bash
# Check DKMS status for new kernel
dkms status

# Manually rebuild for current kernel
sudo dkms install Wiimote-2022/20.22 -k $(uname -r)

# Reload module
sudo modprobe -r hid-wiimote
sudo modprobe hid-wiimote gamepad=1
```

### "Module is in use" when trying to unload

**Find what's using the module:**
```bash
lsmod | grep hid_wiimote
```

**Disconnect Wiimote first:**
```bash
# In bluetoothctl
disconnect XX:XX:XX:XX:XX:XX

# Then unload
sudo modprobe -r hid-wiimote
```

## Nunchuk Issues

### Nunchuk not detected

**Ensure Nunchuk is properly connected:**
1. Remove Nunchuk
2. Clean contacts with isopropyl alcohol
3. Firmly reinsert Nunchuk
4. Reconnect Wiimote

**Check joystick device:**
```bash
evtest
```
Select the Wiimote device and move the Nunchuk joystick - you should see ABS_X and ABS_Y events.

### Nunchuk joystick drift or incorrect calibration

**Test raw values:**
```bash
evtest /dev/input/by-id/*Nintendo*
```

**If values are incorrect:**
1. Ensure Nunchuk is original Nintendo hardware (clones may have different calibration)
2. Leave joystick centered when connecting Wiimote
3. Some games allow joystick calibration in their settings

## Performance Issues

### High CPU usage

**Check for constant event generation:**
```bash
evtest /dev/input/by-id/*Nintendo*
```

If events are constantly firing when no input is given, this may indicate:
1. Joystick drift (see above)
2. Accelerometer noise

**Workaround:**
Some games allow dead zones for joysticks and accelerometers.

### Input lag

**Bluetooth interference:**
1. Move closer to computer
2. Remove other Bluetooth devices
3. Switch to 2.4GHz router channel (5GHz doesn't interfere with Bluetooth)

**USB Bluetooth adapter:**
If using USB Bluetooth adapter, try different USB ports. USB 3.0 can interfere with 2.4GHz Bluetooth.

## Getting More Help

If your issue isn't covered here:

1. **Check kernel logs:**
   ```bash
   dmesg | grep -i wiimote
   dmesg | grep -i hid
   ```

2. **Gather system information:**
   ```bash
   uname -r                    # Kernel version
   dkms status                 # DKMS status
   lsmod | grep hid_wiimote    # Module status
   lsusb                       # USB devices (for Bluetooth adapter)
   hciconfig -a                # Bluetooth adapter info
   ```

3. **Create a GitHub issue** with:
   - Your distribution and version
   - Kernel version
   - Output from commands above
   - Exact error messages
   - Steps to reproduce

4. **Check existing issues:**
   https://github.com/gatopeich/Wiimote-2022/issues
