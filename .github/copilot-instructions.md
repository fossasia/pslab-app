# Copilot Instructions for PSLab App

This document provides guidance for AI coding agents working on the PSLab App repository for the first time.

## Project Overview

**PSLab App** is a Flutter cross-platform application for performing scientific experiments with the Pocket Science Lab (PSLab) open-hardware platform. It provides instruments like oscilloscope, multimeter, wave generator, logic analyzer, and various sensor interfaces.

### Tech Stack
- **Framework**: Flutter (stable channel)
- **Language**: Dart (SDK ^3.5.4)
- **State Management**: Provider pattern
- **Dependency Injection**: GetIt (service locator pattern)
- **Supported Platforms**: Android (primary), iOS, Linux, macOS, Windows, Web

## Repository Structure

```
pslab-app/
├── android/          # Android-specific platform code
├── ios/              # iOS-specific platform code  
├── linux/            # Linux-specific platform code
├── macos/            # macOS-specific platform code
├── windows/          # Windows-specific platform code
├── web/              # Web-specific platform code
├── lib/
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

## Development Workflow

### Prerequisites
- Flutter SDK (stable channel) - version specified in `pubspec.yaml`
- Dart (bundled with Flutter)
- Java (LTS version for Android builds)
- Platform-specific SDKs (Android SDK, Xcode for iOS/macOS)

### Setup Commands
```bash
# Install dependencies
flutter pub get

# Format generated localization files
dart format lib/l10n/

# Check code formatting
dart format --output=none --set-exit-if-changed .

# Analyze code
flutter analyze

# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Build for specific platform
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS
flutter build linux --release        # Linux
```

### Linux-Specific Setup (USB Device Access)
```bash
# Install udev rules for PSLab devices
sudo cp linux/99-pslab.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in for group changes to take effect
```

## CI/CD

### Main Workflows
- **pull-request.yml**: Runs on PRs to `flutter` branch
  - Common build (format, analyze, test)
  - Platform-specific builds (Android, iOS, Windows, Linux, macOS)
  - Screenshot generation (Android, iPhone, iPad)
- **push-event.yml**: Runs on pushes
- **release.yml**: Handles releases

### CI Commands (from `.github/actions/common/action.yml`)
1. `flutter pub get` - Install dependencies
2. `dart format lib/l10n/` - Format localization files (required!)
3. `dart format --output=none --set-exit-if-changed .` - Validate formatting
4. `flutter analyze` - Static analysis
5. `flutter test` - Run tests

**IMPORTANT**: Always format `lib/l10n/` directory before checking overall formatting, as localization files are auto-generated and may not match project formatting style.

## Code Conventions

### Architecture Patterns

#### 1. Provider Pattern (State Management)
- Sensors and instruments use `ChangeNotifier` providers
- Providers are typically created locally in screens using `ChangeNotifierProvider`
- Example pattern in sensor screens:
  ```dart
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        _provider = VL53L0XProvider()
          ..initializeSensors(
            onError: _showSensorErrorSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<VL53L0XProvider>(
        builder: (context, provider, child) {
          // UI code
        },
      ),
    );
  }
  ```

#### 2. Timer-based Data Collection
- Sensor providers commonly use `Timer.periodic` for continuous data collection
- Timers must be cancelled in `stop()` or `dispose()` methods
- Example:
  ```dart
  Timer? _timer;
  
  void start() {
    _timer = Timer.periodic(Duration(milliseconds: _timegapMs), (timer) {
      // Data collection logic
    });
  }
  
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  ```

#### 3. Dependency Injection (GetIt)
- Service locator pattern via `GetIt` package
- Setup in `lib/providers/locator.dart`
- Platform-specific communication handlers registered
- Common services: `ScienceLab`, `CommunicationHandler`, `AppLocalizations`, `BoardStateProvider`
- Access services: `getIt.get<ServiceType>()`

### File Naming Conventions
- **Screens**: `*_screen.dart` (e.g., `oscilloscope_screen.dart`)
- **Providers**: `*_provider.dart` (e.g., `vl53l0x_provider.dart`)
- **Widgets**: `*_widget.dart` for reusable components
- **Models**: Located in `lib/models/`

### Code Style
- **Linting**: Uses `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`)
- **Formatting**: Run `dart format .` before committing
- **Comments**: Match existing style; generally minimal, only when necessary for complex logic
- **Null Safety**: Enabled (Dart 3.5.4+)

## Localization (i18n)

### Critical Information
Localization uses Flutter's official ARB (Application Resource Bundle) format with **generated Dart files that are committed to the repository**.

### Configuration
- **Config file**: `l10n.yaml` at root
- **ARB directory**: `lib/l10n/`
- **Template file**: `lib/l10n/app_en.arb` (English)
- **Generated files**: 
  - `lib/l10n/app_localizations.dart` (base class)
  - `lib/l10n/app_localizations_*.dart` (per-language implementations)

### Adding New Localized Strings

**IMPORTANT**: When adding new UI strings, you **must** update BOTH the ARB file AND regenerate the Dart localization files.

#### Steps:
1. Add new key to `lib/l10n/app_en.arb`:
   ```json
   {
     "myNewString": "My New String",
     "@myNewString": {
       "description": "Description of where this is used"
     }
   }
   ```

2. Regenerate localization files:
   ```bash
   flutter gen-l10n
   # OR
   flutter pub get  # Also triggers regeneration
   ```

3. Format the generated files (REQUIRED for CI):
   ```bash
   dart format lib/l10n/
   ```

4. Use in code:
   ```dart
   AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
   Text(appLocalizations.myNewString)
   ```

5. **Commit the generated files**: The generated `lib/l10n/app_localizations*.dart` files must be committed!

### Common Localization Pitfall
**Error**: CI fails with formatting issues in `lib/l10n/` directory.

**Solution**: Always run `dart format lib/l10n/` after regenerating localization files. The generated code may not match project formatting conventions.

## Instrument Icons and Names

**Critical Pattern**: Instrument icons and names are mapped by **shared list index**.

**Location**: `lib/constants.dart`

```dart
List<String> instrumentIcons = [
  'assets/icons/tile_icon_oscilloscope.png',  // Index 0
  'assets/icons/tile_icon_multimeter.png',    // Index 1
  // ...
];

List<String> instrumentNames = [
  appLocalizations.oscilloscope.toLowerCase(),  // Index 0
  appLocalizations.multimeter.toLowerCase(),    // Index 1
  // ...
];
```

**When adding a new instrument**: Maintain index alignment between `instrumentIcons` and `instrumentNames` arrays. Both must be updated in sync.

## Hardware Communication

### Platform-Specific Handlers
The app uses platform-specific USB communication handlers (see `lib/providers/locator.dart`):
- **Android**: `AndroidUSBCommunicationHandler` (usb_serial package)
- **Linux/Windows/macOS**: `DesktopUSBCommunicationHandler` (flusbserial package)
- **iOS**: `IosNoOpCommunicationHandler` (no-op placeholder)

### PSLab Device IDs
- **PSLab v5**: VendorID `04d8`, ProductID `00df`
- **PSLab v6**: VendorID `10c4`, ProductID `ea60`

### Sensor Communication
- Sensors use I2C communication via `lib/communication/peripherals/i2c.dart`
- Sensor implementations in `lib/communication/sensors/`
- Initialize I2C: `I2C(scienceLab.mPacketHandler)`

## Common Development Tasks

### Adding a New Sensor Screen

1. **Create provider** in `lib/providers/`:
   ```dart
   class MySensorProvider extends ChangeNotifier {
     Timer? _timer;
     // Sensor-specific fields
     
     Future<void> initializeSensors({...}) async { }
     void start() { }
     void stop() { 
       _timer?.cancel();
     }
     
     @override
     void dispose() {
       _timer?.cancel();
       super.dispose();
     }
   }
   ```

2. **Create screen** in `lib/view/`:
   - Follow pattern from `vl53l0x_screen.dart` or `ads1115_screen.dart`
   - Initialize `ScienceLab` and `I2C` in `initState()`
   - Create provider with `ChangeNotifierProvider`
   - Use `Consumer` for reactive UI

3. **Add localized strings** to `lib/l10n/app_en.arb`

4. **Regenerate and format** localization:
   ```bash
   flutter gen-l10n
   dart format lib/l10n/
   ```

5. **Update instrument constants** in `lib/constants.dart` if adding to instruments list

6. **Add navigation** in `lib/main.dart` or relevant screen

### Testing Changes

```bash
# Format code
dart format .

# Analyze
flutter analyze

# Run unit tests
flutter test

# Run on device/emulator
flutter run

# Run specific test file
flutter test test/widget_test.dart

# Run integration tests
flutter test integration_test/
```

## Permissions

### Android Permissions (AndroidManifest.xml)
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - GPS logging
- `RECORD_AUDIO` - Audio oscilloscope
- `INTERNET` - Connectivity
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - Data logging
- `android.hardware.usb.host` - PSLab device communication
- `android.hardware.sensor.ambient_temperature` - Temperature sensors

### iOS Permissions (Info.plist)
- Location usage descriptions
- Camera usage (if applicable)
- Storage access

**When adding features requiring new permissions**: Update both Android and iOS platform manifests.

## Dependencies

### Key Dependencies (from pubspec.yaml)
- **UI**: `flutter_svg`, `google_fonts`, `fl_chart`, `flutter_screenutil`
- **Hardware**: `usb_serial`, `flusbserial`, `sensors_plus`, `light`, `geolocator`, `permission_handler`
- **Audio**: `flutter_audio_capture` (Git dependency from AsCress/flutter_audio_capture)
- **State**: `provider`, `get_it`
- **Utilities**: `logger`, `shared_preferences`, `csv`, `file_picker`, `path_provider`

### Adding Dependencies
1. Add to `pubspec.yaml`
2. Run `flutter pub get`
3. For Git dependencies, specify `url` and `ref`
4. Test on all target platforms if dependency has platform-specific code

## Common Errors and Solutions

### 1. Formatting Failures in CI
**Error**: `dart format --output=none --set-exit-if-changed .` fails

**Solution**: 
```bash
dart format lib/l10n/  # Format generated files first
dart format .          # Then format everything
```

### 2. Missing Localization Getters
**Error**: `appLocalizations.myString` doesn't exist

**Solution**: Regenerate localization files:
```bash
flutter gen-l10n
dart format lib/l10n/
# Commit the generated files
```

### 3. iOS Build Issues
**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### 4. Android Build Issues
**Solution**:
- Ensure Java LTS version is installed
- Run: `flutter clean && flutter pub get`
- Accept Android licenses: `flutter doctor --android-licenses`

### 5. USB Permissions on Linux
**Error**: Cannot access PSLab device

**Solution**: Install udev rules (see Linux-Specific Setup above)

### 6. Timer Not Cancelled Warning
**Error**: Timer still active after dispose

**Solution**: Always cancel timers in provider `stop()` and `dispose()` methods:
```dart
_timer?.cancel();
_timer = null;
```

## Git Workflow

### Branch Strategy
- **flutter**: Main development branch (target for PRs)
- **master**: Stable releases
- **apk**: Auto-generated APK files for testing

### Commit Guidelines
- Single commit per pull request (use `git squash`)
- Commit message format: `tag: commit message` or `Fixes #<issue> <message>`
- Reference issue numbers in commits

### Pull Request Requirements
- Code must pass all CI checks (format, analyze, test, platform builds)
- Include screenshots for UI changes
- Follow uniform design patterns

## Testing

### Current Test Structure
- **Unit tests**: `test/` directory (minimal - mostly placeholder)
- **Integration tests**: `test_integration/` directory

### Running Tests
```bash
# All unit tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

**Note**: Test coverage is currently minimal. When adding new features, follow existing patterns but tests are not strictly required for all changes.

## Build Artifacts and .gitignore

### Excluded from Git
- `build/` - Flutter build outputs
- `.dart_tool/` - Dart tool cache
- `**/Flutter/ephemeral/` - Platform ephemeral files
- `**/Pods/` - iOS CocoaPods
- `.flutter-plugins`, `.flutter-plugins-dependencies`
- Android build artifacts: `/android/app/debug`, `/android/app/profile`, `/android/app/release`

### Included in Git (Important!)
- `lib/l10n/app_localizations*.dart` - Generated localization files (must commit!)
- `pubspec.lock` - Lock file for reproducible builds

## Performance Considerations

### Chart Data Management
- Sensor providers often maintain data point lists (e.g., `List<ChartDataPoint>`)
- Implement `maxDataPoints` limit to prevent memory issues
- Example: `static const int maxDataPoints = 1000;`

### Timer Management
- Use appropriate intervals for sensor polling (typically 100-1000ms)
- Heavier sensors may need longer intervals
- Always clean up timers to prevent leaks

## Documentation

### Code Documentation
- Document complex algorithms or non-obvious logic
- Use Dart doc comments (`///`) for public APIs
- Keep inline comments minimal, matching existing style

### Screenshots
- Store in `docs/images/`
- Update README.md when adding new features
- Include screenshots in PRs for UI changes

## Quick Reference Card

| Task | Command |
|------|---------|
| Install dependencies | `flutter pub get` |
| Format code | `dart format .` |
| Check formatting | `dart format --output=none --set-exit-if-changed .` |
| Analyze code | `flutter analyze` |
| Run tests | `flutter test` |
| Run on device | `flutter run` |
| Build Android APK | `flutter build apk --release` |
| Regenerate localizations | `flutter gen-l10n` |
| Format localizations | `dart format lib/l10n/` |
| Clean build | `flutter clean` |
| Check Flutter setup | `flutter doctor` |

## Resources

- **Project Website**: https://pslab.io
- **Repository**: https://github.com/fossasia/pslab-app
- **Flutter Docs**: https://docs.flutter.dev
- **Issue Tracker**: https://github.com/fossasia/pslab-app/issues
- **Gitter Chat**: https://gitter.im/fossasia/pslab

## Tips for AI Agents

1. **Always check existing patterns**: Look at similar sensor screens (e.g., `vl53l0x_screen.dart`, `ads1115_screen.dart`) before creating new ones
2. **Localization is critical**: Remember to regenerate and format `lib/l10n/` files
3. **Test on multiple platforms**: Flutter is cross-platform; consider platform-specific implications
4. **Memory management**: Always dispose of timers, controllers, and providers
5. **CI will catch issues**: Run `dart format .` and `flutter analyze` locally before committing
6. **Index alignment matters**: Keep `instrumentIcons` and `instrumentNames` arrays synchronized
7. **Commit generated files**: Unlike many projects, localization Dart files ARE committed here
8. **USB communication is platform-specific**: Check platform before implementing hardware features
9. **Provider pattern is standard**: Don't introduce new state management patterns
10. **Minimal test changes**: Tests are sparse; don't remove existing ones, but comprehensive tests aren't required for all PRs

---

*Last Updated: 2026-02-15*
*For questions or clarifications, refer to the project maintainers or open a discussion on GitHub.*
