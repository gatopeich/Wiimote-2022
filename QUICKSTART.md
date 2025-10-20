# Quick Start Guide

This guide provides the fastest way to get your Wiimote working on Linux.

## TL;DR - Quick Commands

### Arch/Manjaro
```bash
git clone https://github.com/gatopeich/Wiimote-2022.git
cd Wiimote-2022
sudo ./install-arch.sh
```

### Ubuntu/Debian
```bash
git clone https://github.com/gatopeich/Wiimote-2022.git
cd Wiimote-2022
sudo apt install dkms linux-headers-$(uname -r)
sudo dkms install .
sudo modprobe hid-wiimote gamepad=1
```

### Other Distributions
```bash
git clone https://github.com/gatopeich/Wiimote-2022.git
cd Wiimote-2022
sudo ./install.sh
```

## Connect Your Wiimote

1. **Load the module** (if not done by install script):
   ```bash
   sudo modprobe hid-wiimote gamepad=1
   ```

2. **Put Wiimote in pairing mode**: Press 1+2 or the sync button

3. **Connect via Bluetooth**:
   ```bash
   bluetoothctl
   power on
   agent on
   scan on
   # Wait for "Nintendo RVL-CNT-01" to appear
   pair XX:XX:XX:XX:XX:XX
   connect XX:XX:XX:XX:XX:XX
   trust XX:XX:XX:XX:XX:XX
   exit
   ```

4. **Verify**: Only one LED should stay lit on the Wiimote

## Common Issues

### "could not load module hid-wiimote.ko: No such file or directory"
❌ Don't use: `sudo insmod hid-wiimote.ko gamepad=1`  
✅ Use instead: `sudo modprobe hid-wiimote gamepad=1`

### Four lights keep flashing
Reload the module before connecting:
```bash
sudo modprobe -r hid-wiimote
sudo modprobe hid-wiimote gamepad=1
# Now connect Wiimote
```

### Steam doesn't detect controller
1. Check gamepad device exists: `ls /dev/input/js*`
2. Enable "Generic Gamepad Configuration Support" in Steam settings

## More Help

- Arch/Manjaro detailed guide: [INSTALL-ARCH.md](INSTALL-ARCH.md)
- Full troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Driver details: [README.md](README.md)

## Load on Boot

To automatically load the module on boot with gamepad support:
```bash
echo "options hid-wiimote gamepad=1" | sudo tee /etc/modprobe.d/hid-wiimote.conf
echo "hid-wiimote" | sudo tee /etc/modules-load.d/hid-wiimote.conf
```
