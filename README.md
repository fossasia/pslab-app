# PSLab App

Repository for the PSLab App for performing experiments with the [Pocket Science Lab](https://pslab.io) open-hardware platform.

[![Build](https://github.com/fossasia/pslab-app/actions/workflows/pull-request.yml/badge.svg)](https://github.com/fossasia/pslab-app/actions/workflows/pull-request.yml)
[![Mailing List](https://img.shields.io/badge/Mailing%20List-FOSSASIA-blue.svg)](https://groups.google.com/forum/#!forum/pslab-fossasia)
![GitHub repo size](https://img.shields.io/github/repo-size/fossasia/pslab-app)
[![Gitter](https://badges.gitter.im/fossasia/pslab.svg)](https://gitter.im/fossasia/pslab?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Twitter Follow](https://img.shields.io/twitter/follow/pslabio.svg?style=social&label=Follow&maxAge=2592000?style=flat-square)](https://twitter.com/pslabio)
[![Translation status](https://hosted.weblate.org/widgets/fossasia/-/pslab-app/svg-badge.svg)](https://hosted.weblate.org/projects/fossasia/pslab-app/)

This repository contains the **PSLab** application, a cross-platform app for performing science and engineering experiments with the **Pocket Science Lab (PSLab)** device. PSLab is an open-source hardware platform that combines multiple laboratory instruments into a single portable device, including an oscilloscope, waveform generator, frequency counter, programmable voltage and current source, logic analyzer, and data logger. The application provides an intuitive interface for interacting with these instruments across multiple platforms.
Our website is at https://pslab.io.

## Download

The PSLab app is available for **Android**, **iOS**, **Windows**, **macOS**, **Linux**, and **Web**.

- Store listings and install guides: [PSLab Application documentation](https://docs.pslab.io/application/Readme.html)
- Development builds (direct downloads): [Download page](https://htmlpreview.github.io/?https://raw.githubusercontent.com/fossasia/pslab-app/refs/heads/app/index.html)

Sign up for the latest updates and test new features early by joining our [beta program](https://play.google.com/apps/testing/io.pslab).

## Buy

* You can get a Pocket Science Lab device from the [FOSSASIA Shop](https://fossasia.com).
* More resellers are listed on the [PSLab website](https://pslab.io/shop/).

## Communication

* The PSLab [chat channel is on Gitter](https://gitter.im/fossasia/pslab).
* Please also join us on the [PSLab Mailing List](https://groups.google.com/forum/#!forum/pslab-fossasia).

## Roadmap

- [x] Establish communication between the cross-platform application and the PSLab device.
- [x] Implement core scientific instruments and expose PSLab hardware functionality.
- [ ] Add wireless connectivity (currently under development).

## Screenshots

<table>
    <tr>
        <td><img src="/docs/readme_images/instrument.jpg"></td>
        <td><img src="/docs/readme_images/nav_drawer.jpg"></td>
        <td><img src="/docs/readme_images/pin_front.jpg"></td>
        <td><img src="/docs/readme_images/pin_back.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/oscilloscope_guide.jpg"></td>
        <td><img src="/docs/readme_images/logic_analyzer_guide.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/oscilloscope.jpg"></td>
        <td><img src="/docs/readme_images/logic_analyzer.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/wave_sin.jpg"></td>
        <td><img src="/docs/readme_images/wave_sqaure.jpg"></td>
        <td><img src="/docs/readme_images/multimeter.jpg"></td>
        <td><img src="/docs/readme_images/power_source.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/sensor_screen.jpg"></td>
        <td><img src="/docs/readme_images/gyroscope.jpg"></td>
        <td><img src="/docs/readme_images/acc_meter.jpg"></td>
        <td><img src="/docs/readme_images/oled_display.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/robotic_arm.jpg"></td>
        <td><img src="/docs/readme_images/oscilloscope_mic.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/compass.jpg"></td>
        <td><img src="/docs/readme_images/luxmeter.jpg"></td>
        <td><img src="/docs/readme_images/soundmeter.jpg"></td>
        <td><img src="/docs/readme_images/logged_data.jpg"></td>
    </tr>
</table>

<table>
    <tr>
        <td><img src="/docs/readme_images/logged_data_chart.jpg"></td>
        <td><img src="/docs/readme_images/faq.jpg"></td>
        <td><img src="/docs/readme_images/settings.jpg"></td>
        <td><img src="/docs/readme_images/about.jpg"></td>
    </tr>
</table>

## Features
|   ***Feature***        | **Description**                                                   | **Status**         |
|------------------------|-------------------------------------------------------------------|--------------------|
| Home Screen            | Show status and version of PSLab device                           | :heavy_check_mark: |
| Instruments            | Exposes PSLab instruments like Oscilloscope, etc                  | :heavy_check_mark: |
| Oscilloscope           | Shows variation of analog signals                                 | :heavy_check_mark: |
| Multimeter             | Measures voltage, current, resistance and capacitance             | :heavy_check_mark: |
| Logical Analyzer       | Captures and displays signals from digital system                 | :heavy_check_mark: |
| Wave Generator         | Generates arbitrary analog and digital waveforms                  | :heavy_check_mark: |
| Power Source           | Generates programmable voltage and currents	                     | :heavy_check_mark: |
| Luxmeter              | Measures the ambient light intensity                               | :heavy_check_mark: |
| Barometer             | Measures the Pressure                                              | :heavy_check_mark: |
| Accelerometer          | Measures the acceleration of the device                           | :heavy_check_mark: |
| Gyrometer             | Measures the rate of rotation                                      | :heavy_check_mark: |
| Compass                | Measures the absolute rotation relative to earth magnetic poles   | :heavy_check_mark: |
| Thermometer            | Measures the ambient temperature                                  | :heavy_check_mark: |
| Gas Sensor             | Detects gases, including NH3, NOx, alcohol, benzene, smoke and CO2| :heavy_check_mark: |
| Robotic Arm Controller | Allows to control 4 servo motors of the robotic arm independently | :heavy_check_mark: |
| OLED Display          | Displays graphics, animations, GIFs, and retro games on external I²C OLED displays | :heavy_check_mark: |
| Sound Meter           | Measures ambient sound levels using the device microphone                           | :heavy_check_mark: |

**Supported Devices:**
- PSLab v5: VendorID `04d8`, ProductID `00df`
- PSLab v6: VendorID `10c4`, ProductID `ea60`

## How to Use

### Android

To use the PSLab device with Android, you need:

- A PSLab device
- A USB OTG cable
- An Android device with USB Host (OTG) support
- The PSLab Android application

Connect the PSLab device to your Android device using the OTG cable. The application will automatically detect the device and establish communication.

### iOS

iOS support currently communicates with the PSLab device over **Wi-Fi** using an **ESP-01** module. This functionality is currently **under development**.

### Windows, macOS, Linux, and Web

These platforms communicate with the PSLab device over USB serial. Before connecting the device, install the **CP210x USB-to-UART Bridge Virtual COM Port (VCP) drivers** for your operating system.

Download the drivers from:

https://www.silabs.com/software-and-tools/usb-to-uart-bridge-vcp-drivers?tab=downloads


## Permissions

### Android

The application requests the following permissions:

| Permission | Purpose |
|------------|---------|
| Location | GPS logging and location-based features |
| Microphone | Audio oscilloscope functionality |
| Internet | Network connectivity |
| Storage | Reading and writing logged data |
| USB Host | Communication with PSLab hardware |
| Motion Sensors | Compass and motion-based features |
| Ambient Temperature Sensor | Device temperature measurements (optional) |

### iOS

The application requests the following permissions:

| Permission | Purpose |
|------------|---------|
| Microphone | Audio oscilloscope functionality |
| Motion Sensors | Compass and motion-based features |
| Storage | Reading and writing logged data |
| Location | GPS logging and location-based features |
| Internet | Network connectivity |

### Desktop (Windows, macOS, Linux)

No runtime permissions are required.

> **Linux:** Users must install the provided `udev` rules and add themselves to the `dialout` group to access USB serial devices.

### Web

No runtime permissions are required.


## Video Demo
* [PSLab Android App Overview](https://www.youtube.com/watch?v=JJfsF0b8M8k).
* [Observing Sound Waveforms Using PSLab Device](https://www.youtube.com/watch?v=5bxDd1PiOMQ).
* [Real-time Sensor Data Logging Using Pocket Science Lab](https://www.youtube.com/watch?v=_A8h6o-UcNo).
* [Generating and Observing Waveforms Using Pocket Science Lab](https://www.youtube.com/watch?v=Ua9_OCR4p8Y).


## Development Environment Setup

### Project Overview

This is a **Cross-platform application** build with **flutter** and **rust** that supports:
- **Android** (primary platform)
- **iOS** (via Wi-Fi only)
- **Linux**
- **macOS**
- **Windows**
- **Web**

### Required Software

**Flutter & Dart**
- Flutter (stable channel)
- Dart (bundled with Flutter)

**Java**
- Java (LTS version required for Android builds)

**Rust**
- Rust (stable toolchain required for Backend)

### Flutter

The user interface and most of the application state management are implemented in **Flutter**. Flutter enables the application to run on multiple platforms from a single codebase while maintaining a consistent user experience.


**Why Flutter?**
- Cross-platform development for Android, iOS, Windows, macOS, Linux, and Web.
- A rich ecosystem of UI libraries and packages.
- High-performance rendering with a native-like user experience.
- Hot reload for faster development and debugging.
- Excellent integration with native code through the **Foreign Function Interface (FFI)**, making it easy to communicate with the Rust-based serial communication backend.

  For setting up the Flutter development environment refer to:

- [docs/flutter.md](https://github.com/fossasia/pslab-app/blob/main/docs/flutter.md)

### Rust

The application uses a **Rust-based serial communication backend** to interface with PSLab hardware. Instead of relying directly on platform-specific hardware communication dependencies, all low-level serial communication is handled by the Rust backend.

**Why Rust?**
- Near bare-metal performance with minimal runtime overhead.
- Memory safety without requiring a garbage collector.
- Reliable and efficient handling of high-frequency serial data streams.
- Cross-platform support through a shared native backend for Flutter.
- Better maintainability for performance-critical hardware communication code.

For setting up the Rust development environment and building the backend, refer to:

- [docs/rust.md](https://github.com/fossasia/pslab-app/blob/main/docs/rust.md)

## Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/fossasia/pslab-app.git
cd pslab-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Platform-Specific Setup for Testing locally

#### Android

No additional setup is required.

#### iOS (macOS only)

Install the CocoaPods dependencies:

```bash
cd ios
pod install
cd ..
```

#### Windows

No additional setup is required. If Windows does not automatically detect your PSLab device, install the appropriate USB drivers.

#### Linux

Install the provided `udev` rules and grant your user access to serial devices:

```bash
sudo cp linux/99-pslab.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

sudo usermod -a -G dialout $USER
```

Log out and log back in for the group changes to take effect.

## Running the Application

### Run the App
The following commands use the **CLI**.
List available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

### Build

#### Debug

Use for development and debugging:

```bash
flutter build apk --debug
```

#### Profile

Use for performance testing and local release-like builds:

```bash
flutter build apk --profile
```

> **Note:** Release builds are generated automatically through CI stored in the **app** branch.

## Testing

Run all tests:

```bash
flutter test
```

Run integration tests:

```bash
flutter test integration_test/
```

### Troubleshooting

**Common Issues:**

1. **USB permissions on Linux:**
    - Ensure udev rules are installed: `ls -la /etc/udev/rules.d/99-pslab.rules`
    - Check user is in dialout group: `groups $USER`

2. **Flutter version mismatch:**
   ```bash
   flutter channel stable
   flutter upgrade
   flutter pub get
   ```

3. **iOS build issues:**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter clean
   flutter pub get
   ```

4. **Android build issues:**
    - Ensure an LTS Java version is installed: java -version
    - Clean build: `flutter clean && flutter pub get`

5. **Git dependency issues:**
   ```bash
   flutter pub deps
   flutter pub get
   ```

### Verify Setup

Follow the steps below to confirm that your local development environment is correctly configured.

#### 1. Check Flutter installation
```bash
flutter doctor
 ```
Resolve any critical issues reported by the command.

#### 2. Install dependencies and run tests
```bash
flutter pub get
flutter test
 ```

#### 3. Run the application
```bash
flutter run
 ```
Run the app on a connected physical device, emulator, or desktop target.


## Translations

We use [Weblate](https://hosted.weblate.org/projects/fossasia/pslab-app/) for managing translations.

If you want to help translate the app into your language, please visit the [PSLab App project on Weblate](https://hosted.weblate.org/projects/fossasia/pslab-app/).

### Technical Details
The app uses the standard Flutter `flutter_localizations` package.
* **Location:** Translation files are stored in `lib/l10n/` in `.arb` (Application Resource Bundle) format.
* **Template:** The source of truth is `lib/l10n/app_en.arb`.
* **Contribution:** While we prefer translations submitted via Weblate to avoid merge conflicts, you can also manually edit the `.arb` files and submit a Pull Request.


## Contributions Best Practices

### Code Practices

Please follow these best practices to make the review process easier for both contributors and reviewers. This allows us to focus on code quality.

- Follow the pull request template whenever you create a pull request.
- Always reference the related issue number at the top of the pull request description.
- If an issue does not already exist, create one before opening the pull request and link it in the description.
- Include screenshots or a short video demonstrating your changes whenever applicable, especially for UI-related changes.
- Always format your Dart code before committing:

  ```bash
  dart format .
  ```

- Ensure your code builds successfully and is free of warnings before pushing. Pull requests with build issues or warnings may fail the CI checks.
- Enable **GitHub Copilot Review** or **ChatGPT Codex Review** in your GitHub account. The AI reviewer may provide useful suggestions on your pull request. Address the relevant comments.

### Branch Policy

We have the following branches
* **main** All development goes on in this branch. If you're making a contribution, you are supposed to make a pull request to Main. Make sure it passes a build checks.
* **development-legacy** Contains the legacy native Android app code.
* **app** Contains automatically generated build artifacts (APK, EXE, IPA, DMG, DEB, etc.) for testing. Anyone can download and install these artifacts directly without needing to build the project locally.


## License

This project is currently licensed under the Apache License 2.0. A copy of [LICENSE](LICENSE) is to be present along with the source code. To obtain the software under a different license, please contact FOSSASIA.
