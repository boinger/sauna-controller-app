# System Specification

The authoritative system specification lives in the ESP32 firmware repo:
https://github.com/boinger/sauna-controller-esp32/blob/main/SPEC.md

This includes the REST API contract, safety model, shared constants, and architecture for both firmware and iOS app.

A single spec is maintained in the firmware repo to avoid drift between the two projects. The app implements the client side of the contract defined there — any API changes start as a SPEC.md update in that repo.
