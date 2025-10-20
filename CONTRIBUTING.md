# Contributing to Wiimote-2022

Thank you for your interest in contributing to the Wiimote-2022 driver!

## Development Setup

### Prerequisites

Make sure you have the following installed:
- Kernel headers for your kernel version
- Build tools (gcc, make, etc.)
- DKMS (for testing DKMS installation)

### Building the Module

#### Manual Build

```bash
cd src
make
```

This creates `hid-wiimote.ko` in the src directory.

#### Test Load

```bash
# Load dependencies
sudo modprobe ff-memless

# Remove old module if loaded
sudo modprobe -r hid-wiimote 2>/dev/null || true

# Load your compiled module
cd src
sudo insmod hid-wiimote.ko gamepad=1
```

#### Test with DKMS

```bash
# Install
sudo dkms install .

# Load
sudo modprobe hid-wiimote gamepad=1

# Check logs
dmesg | tail -50
```

### Testing

1. **Basic functionality**: Connect a Wiimote and verify it appears as a gamepad
   ```bash
   ls -l /dev/input/by-id/*Nintendo*
   evtest  # Select the Wiimote device
   ```

2. **Button mappings**: Test all buttons match the expected layout
   - Use `evtest` or `jstest` to verify button events

3. **Accelerometer**: Tilt the Wiimote and verify axis values change

4. **Nunchuk**: Connect a Nunchuk and test joystick and buttons
   - Verify C and Z buttons work
   - Test joystick in all directions

### Code Style

This project follows the Linux kernel coding style. Key points:

- Use tabs for indentation
- Lines should be 80 characters or less when possible
- Use kernel naming conventions (snake_case for functions/variables)
- Add comments for non-obvious logic

### Making Changes

1. **Small, focused changes**: Each PR should address one specific issue
2. **Test thoroughly**: Test on real hardware before submitting
3. **Update documentation**: Update relevant .md files if behavior changes
4. **Commit messages**: Use clear, descriptive commit messages

### Submitting a Pull Request

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-improvement`
3. Make your changes
4. Test your changes
5. Commit with a clear message
6. Push to your fork
7. Open a Pull Request with:
   - Description of what changed
   - Why the change was needed
   - How you tested it
   - Any relevant issue numbers

### Debugging

#### View kernel logs
```bash
dmesg | grep -i wiimote
dmesg | grep -i hid
```

#### Check module info
```bash
modinfo hid-wiimote
lsmod | grep hid_wiimote
cat /sys/module/hid_wiimote/parameters/gamepad
```

#### Enable debug output
```bash
# Edit src/hid-wiimote-debug.c to enable more verbose logging
# Rebuild and reload module
# Watch logs: dmesg -w
```

### Project Structure

```
Wiimote-2022/
├── src/
│   ├── hid-wiimote-core.c     # Main driver logic
│   ├── hid-wiimote-modules.c  # Extension modules (Nunchuk, etc.)
│   ├── hid-wiimote-debug.c    # Debug/logging functions
│   ├── hid-wiimote.h          # Header file
│   └── Makefile               # Build configuration
├── dkms.conf                  # DKMS configuration
├── README.md                  # Main documentation
├── INSTALL-ARCH.md           # Arch-specific install guide
├── TROUBLESHOOTING.md        # Troubleshooting guide
├── QUICKSTART.md             # Quick start guide
├── install-arch.sh           # Arch installation script
└── install.sh                # Generic installation script
```

### Resources

- [Linux Gamepad Specification](https://www.kernel.org/doc/html/latest/input/gamepad.html)
- [Linux Kernel Module Programming Guide](https://sysprog21.github.io/lkmpg/)
- [xwiimote Documentation](https://github.com/xwiimote/xwiimote)
- [HID Specification](https://www.usb.org/hid)

## Questions?

Feel free to open an issue for:
- Questions about the code
- Feature requests
- Bug reports
- Documentation improvements

Thank you for contributing!
