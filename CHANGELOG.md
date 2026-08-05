# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- iOS equivalent project (SwiftUI + AVFoundation) under `ios/`
- Restructured repository into platform-sibling layout (`android/` + `ios/`)
- GitHub Actions: `ios.yml` (iOS build + unit/UI tests) and `android-ci.yml` (Android unit tests)
- Barcode and QR code scanning
- Camera permission handling
- Scan result display
- Copy to clipboard functionality

### Fixed
- Release camera resources when leaving the scanner screen
- Handle permanently denied camera permission with a link to system settings
- Align unit/instrumented test paths with the declared package
- Complete ViewModel unit tests for Loading / Success / Error states

## [v1.0.0] - 2026-05-25

### Added
- Initial release
- Barcode scanning support (Code 128, Code 39, EAN-13, QR Code, etc.)
- Modern UI with Jetpack Compose
