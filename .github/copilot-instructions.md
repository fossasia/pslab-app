# GitHub Copilot Instructions for PSLab

## Project Overview
PSLab is a cross-platform app (Android, iOS, Windows, Linux) for interfacing with the PSLab hardware device for scientific experiments.

## Technology Stack
- **Framework**: Flutter (Dart)
- **Platforms**: Android, iOS, Windows, Linux
- **Hardware Integration**: USB/Bluetooth communication with PSLab device

## Code Guidelines

### Style
- Follow Flutter/Dart style guidelines
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

### Architecture
- Follow the existing directory structure
- Use BLoC pattern for state management
- Separate UI from business logic
- Use services for hardware communication

### Testing
- Write widget tests for UI components
- Write unit tests for business logic
- Ensure tests pass on all platforms

### Documentation
- Document public APIs
- Add inline comments for hardware-specific code
- Update README for new features

## Review Criteria
- Code must work on all supported platforms
- Follow existing patterns in the codebase
- Include appropriate error handling
- Don't break existing functionality
