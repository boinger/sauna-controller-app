//
//  SaunaSession.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import Foundation
import SwiftData

/// Represents a completed sauna session for history tracking
@Model
final class SaunaSession {
    var startTime: Date
    var endTime: Date?
    var targetTemperature: Double
    var maxTemperatureReached: Double
    var durationMinutes: Int?

    init(
        startTime: Date = Date(),
        endTime: Date? = nil,
        targetTemperature: Double,
        maxTemperatureReached: Double = 0
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.targetTemperature = targetTemperature
        self.maxTemperatureReached = maxTemperatureReached
    }

    /// Marks the session as complete and calculates duration
    func complete() {
        let end = Date()
        endTime = end
        durationMinutes = Int(end.timeIntervalSince(startTime) / 60)
    }
}
