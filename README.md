# PSLab Android App

Repository for the PSLab Android App for performing experiments with the [Pocket Science Lab](https://pslab.io) open-hardware platform.

[![Build](https://github.com/fossasia/pslab-app/actions/workflows/pull-request.yml/badge.svg)](https://github.com/fossasia/pslab-app/actions/workflows/pull-request.yml)
[![Mailing List](https://img.shields.io/badge/Mailing%20List-FOSSASIA-blue.svg)](https://groups.google.com/forum/#!forum/pslab-fossasia)
![GitHub repo size](https://img.shields.io/github/repo-size/fossasia/pslab-app)
[![Gitter](https://badges.gitter.im/fossasia/pslab.svg)](https://gitter.im/fossasia/pslab?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Twitter Follow](https://img.shields.io/twitter/follow/pslabio.svg?style=social&label=Follow&maxAge=2592000?style=flat-square)](https://twitter.com/pslabio)

This repository holds the Android App for performing experiments with [PSLab](https://pslab.io/). PSLab is a tiny pocket science lab that provides an array of equipment for doing science and engineering experiments. It can function like an oscilloscope, waveform generator, frequency counter, programmable voltage and current source and also as a data logger. Our website is at https://pslab.io.

Sign up for the latest updates and test new features early by joining our beta program [here](https://play.google.com/apps/testing/io.pslab).

<a href="https://play.google.com/store/apps/details?id=io.pslab"><img alt="Get it on Google Play" height="80" src="/docs/images/playstore_badge.png"></a>
<a href="https://f-droid.org/app/io.pslab"><img alt="Get it on F-Droid" height="80" src="/docs/images/fdroid_badge.png"></a>

## Buy

* You can get a Pocket Science Lab device from the [FOSSASIA Shop](https://fossasia.com).
* More resellers are listed on the [PSLab website](https://pslab.io/shop/).

## Communication

* The PSLab [chat channel is on Gitter](https://gitter.im/fossasia/pslab).
* Please also join us on the [PSLab Mailing List](https://groups.google.com/forum/#!forum/pslab-fossasia).

## Roadmap
 - [x] First we need to get communication between Android App and PSLab working.
 - [x] Implement Applications and expose PSLab Hardware functionality to the user.
 - [ ] Implement wireless connectivity

## Screenshots

  <table>
      <tr>
       <td><img src="/docs/images/view_device_not_found.png"></td>
       <td><img src="/docs/images/view_home_screen.png"></td>
       <td><img src="/docs/images/view_instrument_panel.png"></td>
       <td><img src="/docs/images/view_about_us.png"></td>
      </tr>
  </table>
  <table>
      <tr>
       <td><img src="/docs/images/instrument_oscilloscope_guide.png"></td>
       <td><img src="/docs/images/instrument_logic_analyzer_guide.png"></td>
      </tr>
    </table>
  <table>
    <tr>
     <td><img src="/docs/images/view_pin_layout_front.png"></td>
     <td><img src="/docs/images/view_pin_layout_back.png"></td>
     <td><img src="/docs/images/view_side_navigation_drawer.png"></td>
     <td><img src="/docs/images/instrument_luxmeter_guide.png"></td>
    </tr>
  </table>
  <table>
    <tr>
     <td><img src="/docs/images/instrument_oscilloscope_channel_view.png"></td>
     <td><img src="/docs/images/instrument_oscilloscope_audiojack_view.png"></td>
    </tr>
  </table>
  <table>
    <tr>
     <td><img src="/docs/images/instrument_wave_generator_analog.png"></td>
     <td><img src="/docs/images/instrument_wave_generator_digital.png"></td>
     <td><img src="/docs/images/instrument_power_source_view.png"></td>
     <td><img src="/docs/images/instrument_multi_meter_view.png"></td>
    </tr>
  </table>
  <table>
    <tr>
     <td><img src="/docs/images/instrument_barometer_view.png"></td>
     <td><img src="/docs/images/view_log_map_location.png"></td>
     <td><img src="/docs/images/view_data_logger.png"></td>
     <td><img src="/docs/images/view_create_config_file.png"></td>
    </tr>
  </table>
  <table>
    <tr>
     <td><img src="/docs/images/instrument_accelerometer_view.png" width = "500"></td>
     <td><img src="/docs/images/instrument_gyro_view.png" width = "500"></td>
     <td><img src="/docs/images/instrument_compass_view.png" width = "500"></td>
     <td><img src="/docs/images/instrument_thermo_view.png" width = "500"></td>
    </tr>
     <tr>
     <td><img src="/docs/images/instrument_sensors_view.png" width = "500"></td>
     <td><img src="/docs/images/instrument_gas_sensor_view.png" width = "500"></td>
     <td><img src="/docs/images/instrument_dust_sensor_view.png" width = "500"></td>
    </tr>
  </table>
  <table>
    <tr>
     <td><img src="/docs/images/instrument_robotic_arm_controller_view.png" width = "500"/></td>
     <td><img src="/docs/images/instrument_logical_analyzer_view.png" width = "500"/></td>
    </tr>
  </table>

## Video Demo
  * [PSLab Android App Overview](https://www.youtube.com/watch?v=JJfsF0b8M8k).
  * [Observing Sound Waveforms Using PSLab Device](https://www.youtube.com/watch?v=5bxDd1PiOMQ).
  * [Real-time Sensor Data Logging Using Pocket Science Lab](https://www.youtube.com/watch?v=_A8h6o-UcNo).
  * [Generating and Observing Waveforms Using Pocket Science Lab](https://www.youtube.com/watch?v=Ua9_OCR4p8Y).

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
| Luxmeter              | Measures the ambient light intensity                              | :heavy_check_mark: |
| Barometer             | Measures the Pressure                                             | :heavy_check_mark: |
| Accelerometer          | Measures the acceleration of the device                           | :heavy_check_mark: |
| Gyrometer             | Measures the rate of rotation                                     | :heavy_check_mark: |
| Compass                | Measures the absolute rotation relative to earth magnetic poles   | :heavy_check_mark: |
| Thermometer            | Measures the ambient temperature                                  | :heavy_check_mark: |
| Gas Sensor             | Detects gases, including NH3, NOx, alcohol, benzene, smoke and CO2| :heavy_check_mark: |
| Robotic Arm Controller | Allows to control 4 servo motors of the robotic arm independently | :heavy_check_mark: |

## Development Environment Setup

### Project Overview

This is a **Flutter cross-platform application** that supports:
- **Android** (primary platform)
- **iOS** 
- **Linux** (with USB device support)
- **macOS**
- **Windows**
- **Web**

The app interfaces with PSLab hardware devices via USB and provides scientific instrument functionality.

### Required Software Versions

**Flutter & Dart:**
- Flutter: `>=3.35.4`
- Dart: `>=3.9.0 <4.0.0`

**Java:**
- Java 17 (required for Android Kotlin compilation)

### Flutter SDK Setup

#### Install Flutter
##### macOS (via Homebrew)
```bash
brew install --cask flutter
```

##### Linux
```
mkdir ~/flutter && cd ~/flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.4-stable.tar.xz
tar -xf flutter_linux_3.35.4-stable.tar.xz
rm -rf flutter_linux_3.35.4-stable.tar.xz
echo 'export PATH="$HOME/flutter/flutter/bin:$PATH"' >> ~/.bash_profile
```

#### Windows
Download from [here](https://docs.flutter.dev/install)
### Flutter development setup (VS Code)

The instructions below explain how to install the Flutter SDK, set up Visual Studio Code with the Flutter and Dart extensions, and run the project using `flutter run`. These steps avoid Android Studio-specific instructions and focus on a minimal, cross-platform Flutter workflow.

Prerequisites
- A supported operating system (Windows, macOS, or Linux).
- A working internet connection to download the Flutter SDK and extensions.

1) Install the Flutter SDK
- Download the Flutter SDK from https://flutter.dev and follow the platform-specific instructions. On Windows, extract the SDK (for example to `C:\src\flutter`) and add the `bin` folder to your PATH environment variable. On macOS/Linux, follow the steps on the Flutter website for adding `flutter` to your PATH.
- After installation, open a terminal (PowerShell on Windows) and run:

```powershell
flutter --version
flutter doctor
```

Resolve any missing components suggested by `flutter doctor`. If you plan to build desktop apps, follow the platform-specific toolchain steps suggested by `flutter doctor` (e.g., install Visual Studio on Windows for Windows desktop builds).

2) Set up Visual Studio Code
- Install VS Code (if you don't have it) and open the project folder in VS Code.
- Install the following extensions from the Extensions view:
  - Flutter (includes the Dart extension)
  - Dart (if the Flutter extension did not install it automatically)
- (Optional) If VS Code cannot find the Flutter SDK, set the `dart.flutterSdkPath` setting to the SDK location in your VS Code settings.

3) Prepare the project and run
- In the project root, fetch packages and generate any code:

```powershell
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # if the project uses code generation
```

- Run the app on the default device (emulator, connected device, or desktop target):

```powershell
flutter run
```

If you want to run on a specific device, list available devices and pass `-d`:

```powershell
flutter devices
flutter run -d windows   # example: run on Windows desktop
```

Notes and troubleshooting
- If you see issues related to missing SDKs or tools, run `flutter doctor` and follow the recommended fixes.
- Building Android APKs or running on Android devices may require Android SDK tools. If you need Android targets later, install the Android SDK separately; Android Studio is not required for Flutter development but can simplify SDK installation.
- For fast iteration in VS Code, use the Debug panel (press F5) or the Flutter toolbar (Run and Debug).

---

### Flutter development setup (VS Code)

The instructions below explain how to install the Flutter SDK, set up Visual Studio Code with the Flutter and Dart extensions, and run the project using `flutter run`. These steps avoid Android Studio-specific instructions and focus on a minimal, cross-platform Flutter workflow.

Prerequisites
- A supported operating system (Windows, macOS, or Linux).
- A working internet connection to download the Flutter SDK and extensions.

1) Install the Flutter SDK
- Download the Flutter SDK from https://flutter.dev and follow the platform-specific instructions. On Windows, extract the SDK (for example to `C:\src\flutter`) and add the `bin` folder to your PATH environment variable. On macOS/Linux, follow the steps on the Flutter website for adding `flutter` to your PATH.
- After installation, open a terminal (PowerShell on Windows) and run:

```powershell
flutter --version
flutter doctor
```

Resolve any missing components suggested by `flutter doctor`. If you plan to build desktop apps, follow the platform-specific toolchain steps suggested by `flutter doctor` (e.g., install Visual Studio on Windows for Windows desktop builds).

2) Set up Visual Studio Code
- Install VS Code (if you don't have it) and open the project folder in VS Code.
- Install the following extensions from the Extensions view:
  - Flutter (includes the Dart extension)
  - Dart (if the Flutter extension did not install it automatically)
- (Optional) If VS Code cannot find the Flutter SDK, set the `dart.flutterSdkPath` setting to the SDK location in your VS Code settings.

3) Prepare the project and run
- In the project root, fetch packages and generate any code:

```powershell
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # if the project uses code generation
```

- Run the app on the default device (emulator, connected device, or desktop target):

```powershell
flutter run
```

If you want to run on a specific device, list available devices and pass `-d`:

```powershell
flutter devices
flutter run -d windows   # example: run on Windows desktop
```

Notes and troubleshooting
- If you see issues related to missing SDKs or tools, run `flutter doctor` and follow the recommended fixes.
- Building Android APKs or running on Android devices may require Android SDK tools. If you need Android targets later, install the Android SDK separately; Android Studio is not required for Flutter development but can simplify SDK installation.
- For fast iteration in VS Code, use the Debug panel (press F5) or the Flutter toolbar (Run and Debug).

---

### Application Flavors

#### Verify Flutter Installation
```bash
flutter doctor
flutter --version
```

### Android Development Setup

**Android Studio is optional** - you can use command-line tools instead.

#### Option 1: Android Studio (Recommended)
1. Install [Android Studio](https://developer.android.com/studio)
2. Install Android SDK and accept licenses:
```bash
flutter doctor --android-licenses
```

#### Option 2: Command Line Tools Only
```bash
# Install Android SDK command-line tools
# Set environment variables
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

**Android Requirements:**
- Compile SDK: 36 (Android 14)
- Min SDK: 24 (Android 7.0)
- Target SDK: 36 (Android 14)
- Java 17 compatibility (configured in build.gradle)

### iOS Development Setup (macOS only)

**Requirements:**
- iOS 14.0+ (specified in Podfile)
- Xcode 12.0+
- CocoaPods

```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios && pod install && cd ..
```

### Linux-Specific Setup

**USB Device Access for PSLab Hardware:**

```bash
# Install udev rules for PSLab devices
sudo cp linux/99-pslab.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to dialout group for serial access
sudo usermod -a -G dialout $USER
# Log out and back in for group changes to take effect
```

**Supported PSLab Devices:**
- PSLab v5: VendorID `04d8`, ProductID `00df`
- PSLab v6: VendorID `10c4`, ProductID `ea60`

### Project Setup

1. **Clone repository:**
```bash
git clone https://github.com/fossasia/pslab-app.git
cd pslab-app
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Platform-specific setup:**
```bash
# iOS (macOS only)
cd ios && pod install && cd ..

# Android - no additional steps needed
```

### Required Permissions

The app requires these permissions (configured in AndroidManifest.xml):

**Android:**
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - GPS logging
- `RECORD_AUDIO` - Audio oscilloscope functionality
- `INTERNET` - Connectivity features
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - Data logging
- `android.hardware.usb.host` - PSLab device communication
- `android.hardware.sensor.ambient_temperature` - Temperature sensors

### Key Dependencies

**Hardware Communication:**
- `usb_serial: ^0.5.0` - USB device communication
- `flusbserial: ^0.3.0` - Additional USB serial support

**Sensors & Hardware:**
- `sensors_plus: ^6.1.2` - Device sensors
- `light: ^4.1.0` - Light sensor
- `geolocator: ^14.0.2` - GPS functionality
- `permission_handler: ^12.0.1` - Runtime permissions

**Audio Processing:**
- `flutter_audio_capture` (Git dependency) - Audio capture for oscilloscope

### Running the Application

#### Development
```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Run with hot reload
flutter run --debug
```

#### Building for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Linux
flutter build linux --release
```

### Testing

```bash
# Unit tests
flutter test

# Integration tests
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
   - Ensure Java 17 is installed: `java -version`
   - Clean build: `flutter clean && flutter pub get`

5. **Git dependency issues:**
   ```bash
   flutter pub deps
   flutter pub get
   ```

**Verify Setup:**
- `flutter doctor` shows no critical issues
- `flutter build apk --debug` completes successfully
- Tests pass: `flutter test` to the repository and click clone or download button.
  4. From the dropdown that appeared, copy the link.
  5. Paste the URL that you copied and press clone.
  6. Android studio should now begin building the project with gradle.
  7. Once this process is complete and Android Studio opens, check the Console for any build errors.

 - _Note:_ If you receive a Gradle sync error titled, "failed to find ...", you should click on the link below the error message (if available) that says _Install missing platform(s) and sync project_ and allow Android studio to fetch you what is missing.

  8. Once all build errors have been resolved, you should be all set to build the app and test it.
  9. To Build the app, go to _Build>Make Project_ (or alternatively press the Make Project icon in the toolbar).
 10. If the app was built successfully, you can test it by running it on either a real device or an emulated one by going to _Run>Run 'app'_ or pressing the Run icon in the toolbar.

If you want build apk only, go to Build>Build apk and apk would be build and directory where apk is generated would be prompted by Android Studio.

You can't debug the usual way as PSLab device is connected to micro-USB port through OTG cable. So Android Device is not connected to PC through USB cable.

To debug over Wi-Fi follow the steps given in this [Blog](http://blog.fossasia.org/android-app-debugging-over-wifi-for-pslab/). 

* **Note :**
If you built your own hardware, change VendorID and/or ProductID in [CommunicationHandler.java](https://github.com/fossasia/pslab-app/blob/master/app/src/main/java/io/pslab/communication/CommunicationHandler.java).

### Permissions Required

1. Record_Audio : It is required for oscilloscope to accept inputs from the phone inbuilt microphone. You can find its implementation in [AudioJack.java](https://github.com/fossasia/pslab-app/blob/development/app/src/main/java/io/pslab/others/AudioJack.java).
2. Access_Fine_Location and Internet : It is required for use in lux meter and compass to get the coordinates for tagging the data on the map. You can find its implementation in [GPSLogger.java](https://github.com/fossasia/pslab-app/blob/development/app/src/main/java/io/pslab/others/GPSLogger.java).
3. Write_External_Storage : It is required for storing log files from instruments that can be transferred out for future analysis.
4. Read_External_Storage : While writing logs in the storage, [CSVLogger.java](https://github.com/fossasia/pslab-app/blob/development/app/src/main/java/io/pslab/others/CSVLogger.java) first checks whether there is any CSVLogger directory exist or not and that require this read permission.  

## Setup to use PSLab with Android App
To use PSLab device with Android, you simply need an OTG cable, an Android Device with USB Host feature enabled ( most modern phones have OTG support ) and PSLab Android App. Connect PSLab device to Android Phone via OTG cable. Rest is handled by App itself.

## Contributions Best Practices

### Code practices

Please help us follow the best practice to make it easy for the reviewer as well as the contributor. We want to focus on the code quality more than on managing pull request ethics.

  * Single commit per pull request.
  * Reference the issue numbers in the commit message. Follow the pattern ``` Fixes #<issue number> <commit message>```
  * Follow uniform design practices. The design language must be consistent throughout the app.
  * The pull request will not get merged until and unless the commits are squashed. In case there are multiple commits on the PR, the commit author needs to squash them and not the maintainers cherrypicking and merging squashes.
  * If the PR is related to any front end change, please attach relevant screenshots in the pull request description.

#### How to `git squash`?

As a tip for new developers those who struggle with squashing commits into one, multiple commits may appear in your pull request mostly due to following reasons.

 * Intentionally adding multiple commit messages after each change without just `git add`ing.
 * Updating the current branch with the remote so a merge commit takes place.

Despite any reason, follow the steps given below to squash all commits into one adhering to our best practices.

  * Setup remote to upstream branch if not set before

`$ git remote add upstream https://github.com/fossasia/pslab-app.git`

  * Check into the branch related to the pull request

`$ git checkout <branch-name>`

  * Perform a soft reset to retain the changes while removing all the commit details

`$ git reset --soft upstream/development`

  * Add files to the staging area

`$ git add <file paths or "." to add everything>`

  * Create a new commit with a proper message following commit message guidelines

`$ git commit -m "tag: commit message"`

  * If you have already made a pull request

`$ git push -f origin <branch-name>`

### Branch Policy

We have the following branches
* **development** All development goes on in this branch. If you're making a contribution, you are supposed to make a pull request to _development_. Make sure it passes a build check on Travis.
* **master** This contains the stable code. After significant features/bugfixes are accumulated on development, we move it to master.
* **apk** This branch contains automatically generated apk file for testing.

### Code style

Please try to follow the mentioned guidelines while writing and submitting your code as it makes easier for the reviewer and other developers to understand.

 * While naming the layout files, ensure that the convention followed is (activity/fragment) _ (name).xml like ```activity_oscilloscope.xml``` , ```fragment_control_main.xml``` .
 * Name the views and widgets defined in the layout files as (viewtype/widget) _ (fragment/activity name) _ (no. in the file) like ```spinner_channel_select_la1``` , ```button_activity_oscilloscope1``` .
 * The activity/fragment file name corresponding to the layout files should be named as                       (activity/fragment name)(activity/fragment).java like ```ChannelsParameterFragment.java``` corresponding to the layout file ```fragment_channels_parameter.xml``` .
 * The corresponding widgets for buttons, textboxes, checkboxes etc. in activity files should be named as (viewtype/widget)(fragment/activity name)(no. in the file) like ```spinnerChannelSelect1``` corresponding to ```spinner_channel_select1``` .

## Developers

### Maintainers
The project is maintained by
- Padmal ([@CloudyPadmal](https://github.com/CloudyPadmal))
- Mario Behling ([@mariobehling](http://github.com/mariobehling))
- Lorenz Gerber ([@lorenzgerber](https://github.com/lorenzgerber))
- Wei Tat ([@cweitat](https://github.com/cweitat))
- Wai Gie ([@woshikie](https://github.com/woshikie))

### Alumni
- Neel Trivedi ([@neel1998](https://github.com/neel1998))
- Akarshan Gandotra ([@akarshan96](https://github.com/akarshan96))
- Asitava Sarkar ([@asitava1998](https://github.com/asitava1998))
- Vivek Singh Bhadauria ([@viveksb007](https://github.com/viveksb007))
- Avjeet ([@Avjeet](https://github.com/Avjeet))
- Abhinav ([@abhinavraj23](https://github.com/abhinavraj23))
- Harsh ([@harsh-2711](https://github.com/harsh-2711))
- Yatri ([@yatri1609](https://github.com/yatri1609))

## License

This project is currently licensed under the Apache License 2.0. A copy of [LICENSE](LICENSE) is to be present along with the source code. To obtain the software under a different license, please contact FOSSASIA.
