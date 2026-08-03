# Flutter Development Setup

This guide explains how to set up the Flutter development environment for the PSLab application.

## Flutter SDK Setup

### Install Flutter

#### macOS (Homebrew)

```bash
brew install --cask flutter
```

#### Linux

Follow the official Flutter setup guide for Linux:
https://docs.flutter.dev/platform-integration/linux/setup

#### Windows

Follow the official Flutter setup guide for Windows:
https://docs.flutter.dev/platform-integration/windows/setup

---

## Flutter Development Setup (VS Code)

The instructions below explain how to install the Flutter SDK, configure Visual Studio Code, and run the project using `flutter run`.

### Prerequisites

- A supported operating system (Windows, macOS, or Linux)
- A working internet connection

### 1. Install the Flutter SDK

Download the Flutter SDK from:

https://docs.flutter.dev/get-started/install

After installation, verify your setup:

```bash
flutter --version
flutter doctor
```

Resolve any issues reported by `flutter doctor`.

### 2. Set Up Visual Studio Code

Install the following extensions:

- Flutter
- Dart

If VS Code cannot locate the Flutter SDK, configure the `dart.flutterSdkPath` setting.

### 3. Prepare the Project

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Run the application:

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d windows
```

---

## Android Development Setup

Android Studio is optional.

### Option 1: Android Studio

Install Android Studio:

https://developer.android.com/studio

Accept Android SDK licenses:

```bash
flutter doctor --android-licenses
```

### Option 2: Command-Line Tools

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### Android Requirements

- Android SDK
- Java (LTS)

---

## iOS Development Setup

Requirements:

- Xcode
- CocoaPods

Install CocoaPods:

```bash
sudo gem install cocoapods
```

Install iOS dependencies:

```bash
cd ios
pod install
cd ..
```

---

## Linux Development Setup

### USB Device Access

```bash
sudo cp linux/99-pslab.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

sudo usermod -a -G dialout $USER
```

Log out and log back in for the group changes to take effect.


---

## Verify Your Installation

```bash
flutter doctor
flutter --version
```