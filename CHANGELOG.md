# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-02-20

### Added

- SwiftUI app with real-time temperature gauge, target temperature control, and heater toggle
- `SaunaManager` with polling, exponential backoff, and debounced commands
- Testable network layer via `NetworkSession` protocol
- Settings view with IP address configuration
- Unit tests with mock network session
