# Project Overview
**PSLab App** is a Flutter cross-platform application for performing
scientific experiments with the Pocket Science Lab (PSLab) open-hardware
platform. It provides instruments like oscilloscope, multimeter, wave
generator, logic analyzer, and various sensor interfaces.

## Tech Stack

- **Framework**: Flutter (stable channel)
- **Language**: Dart
- **State Management**: Provider pattern
- **Dependency Injection**: GetIt (service locator pattern)
- **Supported Platforms**: Android (primary), iOS, Linux, macOS, Windows, Web

## Repository Structure

```text
pslab-app/
├── android/          # Android-specific platform code
├── ios/              # iOS-specific platform code  
├── linux/            # Linux-specific platform code
├── macos/            # macOS-specific platform code
├── windows/          # Windows-specific platform code
├── web/              # Web-specific platform code
├── lib/              # Code shared by all platforms
│   ├── communication/    # Hardware communication layer (USB, sensors, peripherals)
│   ├── providers/        # State management (Provider pattern, ~32 files)
│   ├── view/            # UI screens and widgets
│   ├── models/          # Data models
│   ├── theme/           # App theming and colors
│   ├── l10n/            # Localization (i18n) files
│   ├── others/          # Utilities and helpers
│   ├── constants.dart   # App-wide constants
│   └── main.dart        # App entry point
├── test/            # Unit tests
├── test_integration/# Integration tests
├── assets/          # Images, icons, and other assets
├── .github/
│   ├── workflows/   # CI/CD workflows
│   └── actions/     # Reusable GitHub Actions
├── scripts/         # Build and deployment scripts
└── pubspec.yaml     # Dependencies and project configuration
```

## Coding Standards

- Adhere to the coding style described in <https://dart.dev/effective-dart/style>.
- Adhere to the SOLID design principles described in <https://simple.wikipedia.org/wiki/SOLID_(object-oriented_design)>.
- Adhere to Object-Oriented Design best practices described in <http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod>.
- Keep in mind the architecture recommendations described in <https://docs.flutter.dev/app-architecture/guide>.

## Commit Style

- Adhere to the commit style described in the file `commitstyle.md` in
the `docs` folder of this project.

## UI guidelines

- The UI of the app must be consistent
- The UI of the app should adhere to the best practices for adaptive design described
in <https://docs.flutter.dev/ui/adaptive-responsive/best-practices>.
