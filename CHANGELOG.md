# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- CI: Bump Xcode from 16.2 to 16.4 to restore pre-installed iOS simulator runtime on `macos-15` runners

## [1.0.0] - 2026-02-20

### Added

- SwiftUI app with real-time temperature gauge, target temperature control, and heater toggle
- `SaunaManager` with polling, exponential backoff, and debounced commands
- Testable network layer via `NetworkSession` protocol
- Settings view with IP address configuration
- Unit tests with mock network session
