//
//  SaunaControllerTests.swift
//  SaunaControllerTests
//
//  Created by Jeff Vier on 1/14/26.
//

import Testing
import Foundation
@testable import SaunaController

// MARK: - Mock Network Session

final class MockNetworkSession: NetworkSession, @unchecked Sendable {
    nonisolated(unsafe) var dataForRequestHandler: ((URLRequest) async throws -> (Data, URLResponse))?
    nonisolated(unsafe) var dataFromURLHandler: ((URL) async throws -> (Data, URLResponse))?

    nonisolated func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let handler = dataForRequestHandler else {
            throw URLError(.badServerResponse)
        }
        return try await handler(request)
    }

    nonisolated func data(from url: URL) async throws -> (Data, URLResponse) {
        guard let handler = dataFromURLHandler else {
            throw URLError(.badServerResponse)
        }
        return try await handler(url)
    }
}

// MARK: - Helper

private nonisolated func makeHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

@MainActor
private func makeManager(
    session: MockNetworkSession = MockNetworkSession(),
    address: String = "192.168.1.100"
) -> (SaunaManager, MockNetworkSession, UserDefaults) {
    let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    let manager = SaunaManager(session: session, defaults: defaults)
    manager.controllerAddress = address
    return (manager, session, defaults)
}

// MARK: - SaunaSession Tests

@MainActor
struct SaunaSessionTests {

    @Test func completeCalculatesDuration() {
        let start = Date(timeIntervalSince1970: 0)
        let session = SaunaSession(startTime: start, targetTemperature: 80)

        session.complete()

        #expect(session.endTime != nil)
        #expect(session.durationMinutes != nil)
        #expect(session.durationMinutes! >= 0)
    }

    @Test func completeWithKnownDuration() {
        let start = Date().addingTimeInterval(-600) // 10 minutes ago
        let session = SaunaSession(startTime: start, targetTemperature: 75)

        session.complete()

        #expect(session.durationMinutes == 10)
    }

    @Test func completeWithZeroDuration() {
        let session = SaunaSession(startTime: Date(), targetTemperature: 80)

        session.complete()

        #expect(session.durationMinutes == 0)
    }

    @Test func initDefaults() {
        let session = SaunaSession(targetTemperature: 90)

        #expect(session.endTime == nil)
        #expect(session.durationMinutes == nil)
        #expect(session.maxTemperatureReached == 0)
        #expect(session.targetTemperature == 90)
    }
}

// MARK: - SaunaStatus Tests

@MainActor
struct SaunaStatusTests {

    @Test func decodesFromJSON() throws {
        let json = """
        {
            "current_temp": 65.5,
            "target_temp": 80.0,
            "heating": true,
            "firmware": "2.1.0"
        }
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(SaunaStatus.self, from: json)

        #expect(status.currentTemperature == 65.5)
        #expect(status.targetTemperature == 80.0)
        #expect(status.isHeating == true)
        #expect(status.firmwareVersion == "2.1.0")
    }

    @Test func decodesWithNullFirmware() throws {
        let json = """
        {
            "current_temp": 20.0,
            "target_temp": 75.0,
            "heating": false,
            "firmware": null
        }
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(SaunaStatus.self, from: json)

        #expect(status.firmwareVersion == nil)
        #expect(status.isHeating == false)
    }

    @Test func decodesWithMissingFirmware() throws {
        let json = """
        {
            "current_temp": 20.0,
            "target_temp": 75.0,
            "heating": false
        }
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(SaunaStatus.self, from: json)

        #expect(status.firmwareVersion == nil)
    }
}

// MARK: - SaunaManager Tests

@MainActor
struct SaunaManagerTests {

    @Test func initialStateWithNoSavedAddress() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let manager = SaunaManager(session: MockNetworkSession(), defaults: defaults)

        #expect(manager.controllerAddress == "")
        #expect(manager.currentTemperature == 20.0)
        #expect(manager.targetTemperature == 75.0)
        #expect(manager.isHeating == false)
        #expect(manager.isConnected == false)
        #expect(manager.firmwareVersion == nil)
        #expect(manager.lastError == nil)
        #expect(manager.isCommandInFlight == false)
    }

    @Test func loadsSavedAddress() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        defaults.set("192.168.1.50", forKey: "controllerIP")

        let manager = SaunaManager(session: MockNetworkSession(), defaults: defaults)

        #expect(manager.controllerAddress == "192.168.1.50")
    }

    @Test func updateControllerAddressPersists() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let manager = SaunaManager(session: MockNetworkSession(), defaults: defaults)

        manager.controllerAddress = "10.0.0.1"
        manager.updateControllerAddress("10.0.0.1")

        #expect(defaults.string(forKey: "controllerIP") == "10.0.0.1")
    }

    // MARK: - setHeaterState

    @Test func setHeaterStateSuccess() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/heater")

            // Validate request body
            let body = try JSONDecoder().decode([String: Int].self, from: request.httpBody!)
            #expect(body == ["state": 1])

            let url = request.url!
            let response = makeHTTPResponse(url: url, statusCode: 200)
            return (Data(), response)
        }

        await manager.setHeaterState(true)

        #expect(manager.isHeating == true)
        #expect(manager.lastError == nil)
        #expect(manager.isCommandInFlight == false)
    }

    @Test func setHeaterStateOff() async {
        let (manager, mockSession, _) = makeManager()
        manager.isHeating = true

        mockSession.dataForRequestHandler = { request in
            let body = try JSONDecoder().decode([String: Int].self, from: request.httpBody!)
            #expect(body == ["state": 0])

            let response = makeHTTPResponse(url: request.url!, statusCode: 200)
            return (Data(), response)
        }

        await manager.setHeaterState(false)

        #expect(manager.isHeating == false)
        #expect(manager.lastError == nil)
    }

    @Test func setHeaterStateNon200() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { request in
            let response = makeHTTPResponse(url: request.url!, statusCode: 500)
            return (Data(), response)
        }

        await manager.setHeaterState(true)

        #expect(manager.isHeating == false)
        #expect(manager.lastError?.contains("500") == true)
    }

    @Test func setHeaterStateNetworkError() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await manager.setHeaterState(true)

        #expect(manager.isHeating == false)
        #expect(manager.lastError != nil)
    }

    @Test func setHeaterStateSkipsWhenNoAddress() async {
        let (manager, mockSession, _) = makeManager(address: "")

        var requestMade = false
        mockSession.dataForRequestHandler = { _ in
            requestMade = true
            return (Data(), URLResponse())
        }

        await manager.setHeaterState(true)

        #expect(requestMade == false)
        #expect(manager.isHeating == false)
    }

    @Test func setHeaterStateClearsStaleError() async {
        let (manager, mockSession, _) = makeManager()
        manager.lastError = "stale error"

        mockSession.dataForRequestHandler = { request in
            let response = makeHTTPResponse(url: request.url!, statusCode: 200)
            return (Data(), response)
        }

        await manager.setHeaterState(true)

        #expect(manager.lastError == nil)
    }

    // MARK: - setTargetTemperature

    @Test func setTargetTemperatureSuccess() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/target")

            // Validate request body
            let body = try JSONDecoder().decode([String: Double].self, from: request.httpBody!)
            #expect(body == ["temperature": 85.0])

            let url = request.url!
            let response = makeHTTPResponse(url: url, statusCode: 200)
            return (Data(), response)
        }

        await manager.setTargetTemperature(85.0)

        #expect(manager.targetTemperature == 85.0)
        #expect(manager.lastError == nil)
        #expect(manager.isCommandInFlight == false)
    }

    @Test func setTargetTemperatureNon200() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { request in
            let response = makeHTTPResponse(url: request.url!, statusCode: 400)
            return (Data(), response)
        }

        await manager.setTargetTemperature(85.0)

        #expect(manager.targetTemperature == 75.0) // unchanged
        #expect(manager.lastError?.contains("400") == true)
    }

    @Test func setTargetTemperatureNetworkError() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { _ in
            throw URLError(.timedOut)
        }

        await manager.setTargetTemperature(85.0)

        #expect(manager.targetTemperature == 75.0) // unchanged from default
        #expect(manager.lastError != nil)
    }

    // MARK: - toggleHeater

    @Test func toggleHeaterFlipsState() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { request in
            let url = request.url!
            let response = makeHTTPResponse(url: url, statusCode: 200)
            return (Data(), response)
        }

        #expect(manager.isHeating == false)

        await manager.toggleHeater()
        #expect(manager.isHeating == true)

        await manager.toggleHeater()
        #expect(manager.isHeating == false)
    }

    // MARK: - isCommandInFlight

    @Test func commandInFlightDuringRequest() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { request in
            // In-flight should be true during the request
            // (We can't check from here since it's nonisolated, but we verify
            // it's false before and after the call.)
            let response = makeHTTPResponse(url: request.url!, statusCode: 200)
            return (Data(), response)
        }

        #expect(manager.isCommandInFlight == false)
        await manager.setHeaterState(true)
        #expect(manager.isCommandInFlight == false)
    }

    @Test func commandInFlightResetsOnError() async {
        let (manager, mockSession, _) = makeManager()

        mockSession.dataForRequestHandler = { _ in
            throw URLError(.timedOut)
        }

        await manager.setHeaterState(true)
        #expect(manager.isCommandInFlight == false)
    }

    // MARK: - updateControllerAddress

    @Test func updateControllerAddressClearsConnectionOnEmpty() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let manager = SaunaManager(session: MockNetworkSession(), defaults: defaults)

        manager.controllerAddress = ""
        manager.updateControllerAddress("")

        #expect(manager.isConnected == false)
    }

    // MARK: - fetchStatus (via polling)

    @Test func fetchStatusSuccess() async throws {
        let mockSession = MockNetworkSession()
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!

        let statusJSON = """
        {"current_temp": 65.5, "target_temp": 80.0, "heating": true, "firmware": "2.1.0"}
        """.data(using: .utf8)!

        mockSession.dataFromURLHandler = { url in
            #expect(url.path == "/status")
            let response = makeHTTPResponse(url: url, statusCode: 200)
            return (statusJSON, response)
        }

        // Set saved address so init triggers polling
        defaults.set("192.168.1.100", forKey: "controllerIP")
        let manager = SaunaManager(session: mockSession, defaults: defaults)

        // Give the polling task time to execute
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isConnected == true)
        #expect(manager.currentTemperature == 65.5)
        #expect(manager.targetTemperature == 80.0)
        #expect(manager.isHeating == true)
        #expect(manager.firmwareVersion == "2.1.0")
        #expect(manager.lastError == nil)
    }

    @Test func fetchStatusNon200() async throws {
        let mockSession = MockNetworkSession()
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!

        mockSession.dataFromURLHandler = { url in
            let response = makeHTTPResponse(url: url, statusCode: 503)
            return (Data(), response)
        }

        defaults.set("192.168.1.100", forKey: "controllerIP")
        let manager = SaunaManager(session: mockSession, defaults: defaults)

        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isConnected == false)
    }

    @Test func fetchStatusDecodeFailure() async throws {
        let mockSession = MockNetworkSession()
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!

        mockSession.dataFromURLHandler = { url in
            let badJSON = "not json".data(using: .utf8)!
            let response = makeHTTPResponse(url: url, statusCode: 200)
            return (badJSON, response)
        }

        defaults.set("192.168.1.100", forKey: "controllerIP")
        let manager = SaunaManager(session: mockSession, defaults: defaults)

        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isConnected == false)
    }

    @Test func fetchStatusSkipsWithEmptyAddress() async throws {
        let mockSession = MockNetworkSession()
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!

        var requestMade = false
        mockSession.dataFromURLHandler = { _ in
            requestMade = true
            return (Data(), URLResponse())
        }

        // No saved address — polling won't start
        let manager = SaunaManager(session: mockSession, defaults: defaults)

        try await Task.sleep(for: .milliseconds(100))

        #expect(requestMade == false)
        #expect(manager.isConnected == false)
    }
}

// MARK: - TemperatureGaugeView Logic Tests

// These tests intentionally duplicate the gauge view's progress formula
// (min(current/target, 1.0) with a guard for zero target) to validate the
// algorithm at the unit level, independent of the SwiftUI view.
struct TemperatureGaugeLogicTests {

    @Test func progressCalculation() {
        let currentTemp = 60.0
        let targetTemp = 80.0
        let progress = min(currentTemp / targetTemp, 1.0)

        #expect(progress == 0.75)
    }

    @Test func progressClampsAtOne() {
        let currentTemp = 90.0
        let targetTemp = 80.0
        let progress = min(currentTemp / targetTemp, 1.0)

        #expect(progress == 1.0)
    }

    @Test func progressWithZeroTarget() {
        func computeProgress(currentTemp: Double, targetTemp: Double) -> Double {
            guard targetTemp > 0 else { return 0 }
            return min(currentTemp / targetTemp, 1.0)
        }
        #expect(computeProgress(currentTemp: 60, targetTemp: 0) == 0)
    }
}
