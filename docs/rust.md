# Building PSLab from Source (Rust + Flutter)

PSLab uses **Rust** together with **`flutter_rust_bridge`** to provide high-performance, cross-platform communication with hardware devices such as USB and Serial interfaces.

To build the project successfully, you must install the Rust toolchain along with a few operating system-specific dependencies required by native Rust crates (such as `serialport`).

---

# 1. Install System Dependencies

Before building the project, install the required native build tools and hardware libraries for your operating system.

## Linux (Debian/Ubuntu)

The `serialport` crate depends on `pkg-config` and `libudev-dev` for USB and serial device discovery. `libasound2-dev` is rquired for desktop audio capture.

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libudev-dev libasound2-dev
```

### Fedora / RHEL

Install the equivalent packages using:

```bash
sudo dnf install pkgconf-pkg-config systemd-devel alsa-lib-devel
```

---

## Windows

Rust requires the Microsoft C++ toolchain to compile native libraries.

1. Download and install **Visual Studio Build Tools**.
2. During installation, make sure to select:

- **Desktop development with C++**

This installs the MSVC compiler required by Rust.

---

## macOS

Install the Xcode Command Line Tools:

```bash
xcode-select --install
```

These tools provide the C compiler and system headers required by Rust.

---

# 2. Install Rust (rustup)

PSLab uses the official Rust toolchain distributed through **rustup**.

## Linux / macOS

Install Rust by running:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Follow the on-screen instructions to complete the installation.

---

## Windows

Download and run **`rustup-init.exe`** from the official Rust website:

- https://rustup.rs

Follow the installer and use the default settings unless you have a specific configuration.

---

## Verify the Installation

After installation, restart your terminal (or command prompt) and verify that Rust is installed correctly.

```bash
rustc --version
cargo --version
```

You should see the installed versions of both `rustc` and `cargo`.

---

# 3. Building and Running PSLab

Once Rust and the required system dependencies are installed, you are ready to build the Flutter application.

The project uses **`flutter_rust_bridge`**, which automatically compiles the Rust backend during the Flutter build process.

> **Note:** You do **not** need to run `cargo build` manually.

## Fetch Flutter Dependencies

```bash
flutter pub get
```

## Run the Application

```bash
flutter run
```

During the first build:

- Flutter downloads all Dart dependencies.
- Cargo downloads the required Rust crates.
- The Rust backend is compiled automatically.

The initial build may take several minutes depending on your internet connection and system performance.

Subsequent builds will be significantly faster because Cargo caches compiled dependencies.

---

# 4. Developing Rust Code

If you modify the Rust API (typically located in `rust/src/api/simple.rs`), you must regenerate the Flutter bindings so Dart can access the newly added Rust functions.

---

## Install the Code Generator

Install the Flutter Rust Bridge code generator once:

```bash
cargo install flutter_rust_bridge_codegen
```

---

## Regenerate the Bindings

From the root directory of the project, run:

```bash
flutter_rust_bridge_codegen generate
```

Run this command **every time** you add, remove, or modify Rust API functions.

---

## Rebuild the Application

After the bindings are regenerated:

1. Stop the currently running application.
2. Run the application again.

```bash
flutter run
```

The updated Rust APIs will now be available from Flutter.

---

# Development Workflow Summary

```text
Install system dependencies
            │
            ▼
      Install Rust (rustup)
            │
            ▼
      flutter pub get
            │
            ▼
        flutter run
            │
            ▼
   Modify Rust code (optional)
            │
            ▼
flutter_rust_bridge_codegen generate
            │
            ▼
        flutter run
```