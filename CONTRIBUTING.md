# Contributing to Sauna Controller iOS App

Thanks for your interest in contributing!

## Getting Started

1. **Xcode 15.0+** is required (iOS 17 SDK)
2. Clone the repo and open `SaunaController/SaunaController.xcodeproj`
3. Select a development team in Signing & Capabilities
4. Build and run on an iOS Simulator

## Build & Test

```bash
# Build
xcodebuild build \
  -scheme SaunaController \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet

# Test
xcodebuild test \
  -scheme SaunaController \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SaunaControllerTests \
  -quiet
```

## Critical Build Settings

This project uses two non-default Swift settings that **will** trip you up if you're not aware of them:

### `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`

All types default to `@MainActor`. You don't need to annotate views or observable objects, but you **do** need explicit `@MainActor` on free functions and test structs that interact with MainActor-isolated types.

### `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`

Imports are not transitive. If your file uses `@Published`, you must `import Combine` — even though Foundation might seem sufficient. Do not remove framework imports without verifying they aren't needed.

## Pre-Commit Gates

- **Build** with zero warnings
- **All tests pass** — never fix a failure by deleting or stubbing out a test
- **SwiftUI previews** render correctly

## Specification Contract

The REST API contract is defined in the ESP32 firmware repo's [SPEC.md](https://github.com/boinger/sauna-controller-esp32/blob/main/SPEC.md). API changes (endpoints, JSON schemas, status codes) are proposed there, not here.

## Workflow

1. **Open an issue** describing the change you'd like to make
2. **Discuss** the approach before writing code
3. **Fork and branch** from `main`
4. **Implement** with passing gates (see above)
5. **Open a PR** referencing the issue

## Architecture Notes

- `SaunaManager` is the single source of truth — all state flows through it
- Network access is abstracted via the `NetworkSession` protocol for testability
- Views should be lightweight — business logic belongs in `SaunaManager`
- See the [README](README.md#architecture) for more detail
