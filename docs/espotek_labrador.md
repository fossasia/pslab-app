<!-- markdownlint-disable MD043 -->

# EspoTek Labrador How to Use with PSLab

This guide details how to set up, connect, and use the **EspoTek Labrador**
open-source USB multi-instrument board with the **PSLab** cross-platform
application, including platform setup, hardware pinout reference, available
instruments, and step-by-step firmware flashing.

---

## Table of Contents

1. [Overview and Hardware Specifications](#overview-and-hardware-specifications)
2. [How to Use by Platform](#how-to-use-by-platform)
   - [Android](#android)
   - [Desktop (Windows, macOS, Linux)](#desktop-windows-macos-linux)
   - [Web](#web)
   - [iOS (Compatibility Note)](#ios-compatibility-note)
3. [Connecting the Device in PSLab](#connecting-the-device-in-pslab)
   - [Connect Device Screen](#connect-device-screen)
   - [Board Specifications Card](#board-specifications-card)
   - [Interactive Pin Layout Screen](#interactive-pin-layout-screen)
4. [Using Instruments](#using-instruments)
   - [Oscilloscope](#oscilloscope)
   - [Waveform Generator](#waveform-generator)
   - [Multimeter](#multimeter)
   - [Power Supply](#power-supply)
   - [Logic Analyzer](#logic-analyzer)
   - [Digital Outputs](#digital-outputs)
5. [Firmware Architecture and Variants](#firmware-architecture-and-variants)
   - [Microcontroller and USB Identifiers](#microcontroller-and-usb-identifiers)
   - [Available Firmware Variants](#available-firmware-variants)
6. [Flashing Firmware with the PSLab App](#flashing-firmware-with-the-pslab-app)
   - [Entering Bootloader Mode (DFU)](#entering-bootloader-mode-dfu)
   - [In-App Flashing Walkthrough](#in-app-flashing-walkthrough)
7. [Operating System and Driver Setup](#operating-system-and-driver-setup)
   - [Windows Driver Setup (WinUSB)](#windows-driver-setup-winusb)
   - [Linux udev Rules](#linux-udev-rules)
   - [macOS Driver Information](#macos-driver-information)
8. [Troubleshooting and FAQ](#troubleshooting-and-faq)

---

## Overview and Hardware Specifications

The **EspoTek Labrador** is an all-in-one USB laboratory instrument powered
by an Atmel (Microchip) **ATxmega32A4U** microcontroller. It combines an
oscilloscope, waveform generator, power supply, logic analyzer, and
multimeter onto a compact single board.

Hardware Capabilities:

- **Microcontroller**: Atmel ATxmega32A4U (32 MHz 8/16-bit AVR RISC,
  32KB Flash, 4KB SRAM)
- **Operating Voltage**: 5.0V DC via Micro-USB, onboard 3.3V Low-Dropout
  (LDO) regulator
- **Power Supply Output**: Boost DC-DC converter programmable from 4.5V up
  to 12.0V DC (up to 15V max)
- **Oscilloscope**: 2 Analog Channels (`CH1`, `CH2`), up to 750 kSPS
  sampling rate, 8-bit ADC, AC and DC coupling (-20V to +20V input range)
- **Waveform Generator**: 2 Analog Channels (`W1`, `W2`), arbitrary, sine,
  triangle, and square waves up to ~1 MHz
- **Logic Analyzer**: 2 Digital Channels (`LA1`, `LA2`), 3.3V logic level
  capture up to 3 MSPS
- **Digital Outputs**: 4 Digital Channels (`DO1`, `DO2`, `DO3`, `DO4`), 3.3V
  push-pull digital outputs
- **Multimeter**: DC Voltmeter (-10.0V to +10.0V) and Resistance measurement
  (up to 1.0 MΩ)
- **Connectivity**: Native full-speed USB (Bulk streaming protocol)

---

## How to Use by Platform

### Android

To use the EspoTek Labrador with an Android device, you need:

- An **EspoTek Labrador** board
- A **USB OTG (On-The-Go) cable or adapter** (Micro-USB or USB-C to USB-A)
- An Android device running Android 6.0+ with **USB Host (OTG)** support
- The **PSLab Android application**

Connection Steps:

1. Connect the micro-USB cable from your Labrador board into the USB OTG
   adapter.
2. Plug the OTG adapter into your Android smartphone or tablet.
3. Android will display a system dialog asking:
   *"Open PSLab to handle this USB device?"*
4. Tap **OK** or check
   *"Always open PSLab when EspoTek Labrador is connected"*.
5. The PSLab application will launch or switch into active mode, detect the
   Labrador board (`VID: 0x03EB, PID: 0xBA94`), establish USB communication,
   and display the device specifications on the **Connect Device** screen.

---

### Desktop (Windows, macOS, Linux)

Desktop platforms communicate directly with the EspoTek Labrador via
high-speed native USB endpoints through the cross-platform Rust backend.

#### Windows

- Connect the Labrador board to any available USB port.
- Labrador requires the **WinUSB** driver for both runtime communication and
  firmware flashing.
- If Windows does not automatically assign WinUSB:

  1. Download and run [Zadig](https://zadig.akeo.ie).
  2. Select **Options > List All Devices**.
  3. Select **EspoTek Labrador** (VID `03EB`, PID `BA94`).
  4. Select **WinUSB** in the target driver box and click **Replace Driver**
     or **Install Driver**.
  5. Repeat the process in bootloader mode (`03EB`, PID `2FE4`) if flashing
     firmware on Windows.

#### macOS

- Connect the Labrador board to your Mac via a USB cable or USB-C hub.
- macOS supports the device natively through `libusb` and I/O Kit. No
  third-party driver installations are required.

#### Linux

- Connect the Labrador board to your Linux system.
- To access the device without `root` permissions, configure the `udev`
  rules as described in the [Linux udev Rules](#linux-udev-rules) section
  below.
- Once the udev rules are loaded, start the PSLab desktop application; the
  board will be recognized immediately.

---

### Web

The PSLab Web application communicates with the EspoTek Labrador using the
browser's native **WebUSB API**.

Requirements:

- A Chromium-based browser supporting WebUSB (Google Chrome, Microsoft Edge,
  Opera, or Brave) on Windows, macOS, Linux, ChromeOS, or Android.

Connection Steps:

1. Open the PSLab Web application in your browser.
2. Navigate to the **Connect Device** screen.
3. Click the **Connect Labrador** button.
4. Your browser will display a native WebUSB device pairing popup.
5. Select **EspoTek Labrador** from the list and click **Connect**.
6. The web app immediately claims the bulk endpoints and unlocks all
   instrument screens.

---

### iOS (Compatibility Note)

The EspoTek Labrador communicates strictly over a direct wired USB connection
(ATxmega32A4U USB controller). Because iOS requires proprietary Apple MFi
(Made for iPhone/iPad) authentication chips for external wired USB accessories,
and Labrador does not possess an onboard Wi-Fi module (such as the ESP-01 or
ESP32 found on PSLab boards), **iOS is not currently supported** for the
EspoTek Labrador.

---

## Connecting the Device in PSLab

### Connect Device Screen

When you open the PSLab app with your EspoTek Labrador connected, the
**Connect Device** screen provides real-time status:

- **Connected Badge**: Displays a green checkmark indicating successful
  hardware handshake.
- **Connection Method**: Indicates whether the board is communicating via
  `USB` (Android/Desktop) or `WebUSB` (Web).
- **Disconnect Button**: Safely disables the programmable boost converter,
  halts active logic capture/sampling, and releases the USB endpoints.

### Board Specifications Card

Below the status card, the **Board Specifications** card lists Labrador's
hardware features and pin capabilities:

- Main Microcontroller & clock frequency
- Operating Voltage & power rails
- Power Supply Output ranges
- Oscilloscope channels, sampling rates, and input ranges
- Waveform Generator output channels & wave types
- Logic Analyzer sampling limits
- Digital Output pins
- Multimeter voltmeter & ohmmeter capabilities

### Interactive Pin Layout Screen

Tap **View Pin Layout** at the bottom of the specifications card to open the
interactive pin layout viewer:

- A high-resolution photo of the Labrador board is presented with interactive
  pin overlay points.
- Tap any pin on the graphic or select from the pin list to view its
  description, signal type, and voltage ratings:
  - **3.3V**: Regulated 3.3V DC power output for external circuits.
  - **GND**: Common system ground pins.
  - **CH1_DC / CH1_AC**: Oscilloscope Channel 1 with DC or AC coupling.
  - **CH2_DC / CH2_AC**: Oscilloscope Channel 2 with DC or AC coupling.
  - **W1_DC / W1_AC**: Waveform Generator 1 output with DC or AC coupling.
  - **W2_DC / W2_AC**: Waveform Generator 2 output with DC or AC coupling.
  - **DO1, DO2, DO3, DO4**: 3.3V Digital Outputs (`DO1` is also used for
    bootloader hardware entry).
  - **LA1, LA2**: Logic Analyzer digital inputs.
  - **PSU_POS / PSU_GND**: Programmable DC boost power supply positive and
    ground terminals.

---

## Using Instruments

### Oscilloscope

- **Channels**: 2 analog channels (`CH1` and `CH2`).
- **Coupling**:
  - To inspect signals with DC offset, connect to `CH1_DC` or `CH2_DC`.
  - To inspect pure AC waveforms (blocking DC bias), connect to `CH1_AC` or
    `CH2_AC`.
- **Sampling Rate**: Up to 750 kSPS across channels.
- **Controls**: In the PSLab Oscilloscope screen, toggle CH1 and CH2, adjust
  timebase, voltage scale, and set edge triggers.

### Waveform Generator

- **Channels**: 2 analog outputs (`W1` and `W2`).
- **Waveforms**: Sine, Triangle, and Square wave output.
- **Configuration**: Adjust frequency (up to 1 MHz for square, up to
  audio/sub-MHz frequencies for sine and triangle) and peak-to-peak amplitude.
- **Probing**: Use `W1_DC` / `W2_DC` for DC-coupled outputs or `W1_AC` /
  `W2_AC` for AC-coupled outputs.

### Multimeter

- **DC Voltmeter**: Measure voltages from -10.0V to +10.0V DC by probing
  between `CH1_DC` and `GND`.
- **Ohmmeter / Resistance**: Measure resistor values up to 1.0 MΩ using the
  onboard reference divider.

### Power Supply

- **Programmable Voltage**: Configure boost converter output from 4.5V up to
  12.0V DC.
- **Output Terminals**: Connect external circuits across `PSU_POS` (+) and
  `PSU_GND` (-).
- **Safety**: Always verify target voltage before connecting delicate external
  components.

### Logic Analyzer

- **Channels**: 2 digital channels (`LA1` and `LA2`).
- **Logic Level**: 3.3V CMOS/TTL compatible (0V to 3.3V).
- **Sampling**: Capture digital transitions, serial buses, and pulse trains up
  to 3 MSPS.

### Digital Outputs

- **Pins**: `DO1`, `DO2`, `DO3`, and `DO4`.
- **Level**: 3.3V digital push-pull outputs for driving LEDs, logic gates, or
  triggering external hardware.

---

## Firmware Architecture and Variants

### Microcontroller and USB Identifiers

The EspoTek Labrador features an Atmel **ATxmega32A4U** with a built-in
Atmel USB DFU (Device Firmware Upgrade) bootloader stored in dedicated
non-volatile boot memory.

The board operates under two distinct USB identities:

| State | Mode | Vendor ID | Product ID | Description |
|---|---|---|---|---|
| Runtime | Normal | `0x03EB` | `0xBA94` | EspoTek Labrador firmware |
| Bootloader | DFU | `0x03EB` | `0x2FE4` | ATxmega32A4U DFU Bootloader |

### Available Firmware Variants

The PSLab app bundles pre-tested firmware images in `assets/firmware/`:

1. **`labrafirm_000c_03.hex` (Variant 03 Bulk - Recommended & Default)**:
   - Configured for USB Bulk Transfer endpoints.
   - Provides reliable, packet-loss-free data transfer with high throughput
     across Android, Desktop, and WebUSB.
2. **`labrafirm_0007_01.hex` (Variant 01 - Legacy Isochronous)**:
   - Legacy isochronous audio streaming variant designed for original desktop
     Qt clients.
3. **`labrafirm_0007_02.hex` (Variant 02 - Legacy Isochronous)**:
   - Alternative legacy isochronous variant.

---

## Flashing Firmware with the PSLab App

The PSLab application includes a complete, native in-app firmware flasher for
the EspoTek Labrador. You can flash or restore the firmware on Android,
Windows, macOS, Linux, and Web without needing external tools like
`dfu-programmer` or Atmel FLIP.

### Entering Bootloader Mode (DFU)

Before the board can accept new firmware, it must enter DFU bootloader mode
(`VID: 03EB, PID: 2FE4`). You can enter bootloader mode using either method:

#### Method 1: Hardware Jumper

Recommended for unprogrammed or unresponsive boards:

1. Unplug the Labrador's USB cable from your computer or phone.
2. Using a female-to-female DuPont jumper wire, **connect pin `DO1` (Digital
   Out 1) directly to any `GND` pin**.
3. With the jumper in place, plug the USB cable back into your device.
4. The board will bypass application firmware and stay in the ATxmega DFU
   bootloader (`03EB:2FE4`).
5. *Keep the jumper connected during the flash process.*

#### Method 2: Software Jump from the PSLab App

1. With your Labrador connected in normal mode, open the PSLab app.
2. Open the navigation drawer and tap **Firmware Flasher**.
3. Select Target: **EspoTek Labrador**.
4. Tap **Jump Connected Board to Bootloader**.
5. The app sends USB vendor request `0xA7`, instructing the Labrador
   firmware to jump directly into its bootloader.
6. The app will confirm: *"Switched board into DFU bootloader mode."*

---

### In-App Flashing Walkthrough

1. **Navigate to Firmware Flasher**:
   - Open the PSLab navigation drawer and select **Firmware Flasher**.

2. **Select Target**:
   - Tap the target device dropdown at the top and select
     **EspoTek Labrador**.

3. **Choose Firmware Source**:
   - **Built-in Firmware (Recommended)**: Select `labrafirm_000c_03.hex
     (Variant 03 Bulk USB Transfer)`.
   - **Local File**: If flashing a custom `.hex` file, select *Local File* and
     tap *Pick Local File*.

4. **Start Flashing**:
   - Tap the red **Flash Firmware** button.

5. **Confirmation Dialog**:
   - A dialog will appear asking to confirm that the Labrador board is plugged
     in with `DO1` connected to `GND`, or already in DFU bootloader mode.
   - Tap **Continue**.

6. **Monitor Flashing Progress**:
   The flasher executes the full DFU programming cycle with real-time
   feedback:

   - **Connecting (5%)**: Handshakes with the USB DFU bootloader.
   - **Erasing Flash (15%)**: Erases the ATxmega32A4U application flash pages.
   - **Writing Flash (20% – 90%)**: Writes firmware blocks with real-time
     percentage progress.
   - **Verifying & Launching (95%)**: Verifies programmed bytes and issues the
     DFU launch command.
   - **Success (100%)**: Displays *"SUCCESS! Labrador bulk firmware flashed
     successfully."*

7. **Finalize**:
   - If you used the hardware jumper method, **remove the jumper wire between
     `DO1` and `GND`**.
   - Unplug and replug the USB cable.
   - Return to the **Connect Device** screen; the board will now enumerate
     under runtime mode (`03EB:BA94`) and connect immediately.

---

## Operating System and Driver Setup

### Windows Driver Setup (WinUSB)

Windows requires the **WinUSB** driver to communicate with both runtime
firmware and the DFU bootloader.

If the board is not detected automatically:

1. Download **Zadig** from [zadig.akeo.ie](https://zadig.akeo.ie).
2. In Zadig, open the **Options** menu and check **List All Devices**.
3. For runtime operation:
   - Select **EspoTek Labrador** (Hardware ID: `USB\VID_03EB&PID_BA94`).
   - Choose **WinUSB (v6.1.7600.16385 or newer)**.
   - Click **Install Driver** or **Replace Driver**.
4. For DFU bootloader flashing:
   - Put the board into bootloader mode (`DO1` to `GND`).
   - Select **ATxmega32A4U DFU** (Hardware ID: `USB\VID_03EB&PID_2FE4`).
   - Choose **WinUSB** and click **Install Driver**.

---

### Linux udev Rules

Linux restricts direct USB access to unprivileged users by default. To use
and flash EspoTek Labrador without needing `sudo`:

1. Copy the PSLab udev rules file to `/etc/udev/rules.d/`:

   ```bash
   sudo cp linux/99-pslab.rules /etc/udev/rules.d/
   ```

2. Ensure the rules file includes both Labrador runtime and bootloader device
   IDs:

   ```udev
   # EspoTek Labrador (Runtime Mode)
   SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", \
     ATTRS{idProduct}=="ba94", MODE="0666", GROUP="plugdev"

   # EspoTek Labrador (DFU Bootloader Mode)
   SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", \
     ATTRS{idProduct}=="2fe4", MODE="0666", GROUP="plugdev"
   ```

3. Add your user account to the `plugdev` and `dialout` groups:

   ```bash
   sudo usermod -a -G plugdev,dialout $USER
   ```

4. Reload and trigger the updated rules:

   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

5. Log out and log back in for group membership changes to take effect.

---

### macOS Driver Information

No additional drivers or permission scripts are required on macOS. The PSLab
desktop application uses native USB communication (`libusb` / IOKit) and will
automatically recognize the Labrador board upon connection.

---

## Troubleshooting and FAQ

### Device is not detected when plugged in

- **Check USB OTG cable (Android)**: Ensure you are using a data-capable USB
  OTG cable, not a power-only charging cable. Verify that OTG / USB Host is
  enabled in your Android device's System Settings (some devices such as
  OnePlus / Oppo / Vivo require manually enabling "OTG Connection").
- **Check USB Cable quality**: Micro-USB cables with high resistance can cause
  voltage drops that prevent the board from enumerating.
- **Inspect Pin Layout**: Ensure `DO1` is not accidentally bridged to `GND`
  during normal operation (which forces bootloader mode instead of runtime
  mode).

### Flashing fails with "No Labrador board found in DFU bootloader mode"

- The microcontroller is currently in runtime mode (`PID: BA94`) instead of
  bootloader mode (`PID: 2FE4`).
- Unplug the board, place a firm jumper connection between `DO1` and `GND`,
  and replug the USB cable before clicking Flash Firmware.
- On Windows, ensure Zadig has assigned the **WinUSB** driver to device
  `03EB:2FE4`.

### Board is stuck in bootloader mode after flashing

- If you used a physical jumper wire between `DO1` and `GND`, remember to
  **disconnect the jumper wire** and reconnect the USB cable so the board can
  boot its main firmware.

### WebUSB device prompt does not show EspoTek Labrador

- Ensure you are using a Chromium-based browser (Google Chrome, Microsoft
  Edge, Opera, Brave). Mozilla Firefox and Apple Safari do not support the
  WebUSB API.
- On Linux, verify that your user account has read/write permissions via
  `udev` rules as described above.
