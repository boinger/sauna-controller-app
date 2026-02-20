# Sauna Controller - iOS App

Native iOS app for controlling your ESP32-based sauna.

## Features

- **Real-time Monitoring**: Live temperature display with visual gauge
- **Target Temperature**: Set and track your desired sauna temperature
- **One-tap Control**: Start/stop heating with a single tap
- **Local Network**: Direct communication with controller — no cloud required

## Requirements

- iOS 17.0+
- Xcode 15.0+
- ESP32 Sauna Controller on the same network

## Setup

1. Open `SaunaController.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on your device

## Configuration

1. Launch the app
2. Go to Settings (gear icon)
3. Enter your ESP32's IP address
4. The app will connect automatically

## Architecture

The app uses **MVVM** with SwiftUI:

- **`SaunaManager`** — Central `ObservableObject` and single source of truth. Handles polling, commands, and state. Injected via `@StateObject` / `@EnvironmentObject`.
- **`NetworkSession` protocol** — Abstracts `URLSession` for testability. `URLSession` conforms via extension.
- **Polling with backoff** — 2-second interval when connected, exponential backoff up to 30 seconds when disconnected.
- **Debounced inputs** — Target temperature (300ms) and IP address changes (500ms) use Task-cancellation debouncing to avoid flooding the controller.

## Project Structure

```
SaunaController/
├── SaunaControllerApp.swift        # App entry point
├── ContentView.swift               # Main view, error alerts, temp debounce
├── SaunaSession.swift              # SwiftData model for session history
├── Views/
│   ├── TemperatureGaugeView.swift  # Circular temperature gauge
│   ├── TargetTemperatureView.swift # Slider + buttons (local @State)
│   ├── PowerControlView.swift      # Heater on/off toggle
│   └── SettingsView.swift          # IP config, status, about
├── Models/
│   └── SaunaStatus.swift           # Codable model for /status response
└── Services/
    └── SaunaManager.swift          # NetworkSession protocol, manager
```

## Testing

```bash
xcodebuild test \
  -scheme SaunaController \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SaunaControllerTests \
  -quiet
```

Tests use the [Swift Testing](https://developer.apple.com/documentation/testing) framework (`@Test`, `#expect`). `SaunaManager` is tested via a mock `NetworkSession` with injectable responses.

## Local Network Only

This app communicates directly with the ESP32 over your local WiFi network using plain HTTP. There is no cloud service, no user accounts, and no data leaves your network. This is by design — the ESP32 runs a simple REST API on port 8080 that the app talks to directly. See the [firmware repo](https://github.com/boinger/sauna-controller-esp32) for the full API specification.

## Related

- [Sauna Controller ESP32 Firmware](https://github.com/boinger/sauna-controller-esp32) — The open-source firmware this app controls

## License

Apache License 2.0 — see [LICENSE](LICENSE)

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) and open an issue first to discuss proposed changes.
