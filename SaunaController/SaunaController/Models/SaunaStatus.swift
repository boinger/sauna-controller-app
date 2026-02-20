//
//  SaunaStatus.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import Foundation

/// Response model for `GET /status` on the ESP32 controller (port 8080).
/// JSON fields use snake_case; `CodingKeys` maps them to Swift camelCase.
struct SaunaStatus: Codable {
    let currentTemperature: Double
    let targetTemperature: Double
    let isHeating: Bool
    let firmwareVersion: String?

    enum CodingKeys: String, CodingKey {
        case currentTemperature = "current_temp"
        case targetTemperature = "target_temp"
        case isHeating = "heating"
        case firmwareVersion = "firmware"
    }
}
