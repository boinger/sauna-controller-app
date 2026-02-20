//
//  SaunaManager.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import Combine
import Foundation

// MARK: - Protocols

protocol NetworkSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}

// MARK: - SaunaManager

/// Manages communication with the ESP32 sauna controller
@MainActor
class SaunaManager: ObservableObject {
    // MARK: - Published State

    @Published var currentTemperature: Double = 20.0
    @Published var targetTemperature: Double = 75.0
    @Published var isHeating: Bool = false
    @Published var isConnected: Bool = false
    @Published var firmwareVersion: String?
    @Published var lastError: String?

    @Published var isCommandInFlight: Bool = false

    // MARK: - Properties

    @Published var controllerAddress: String = ""
    nonisolated(unsafe) private var pollingTask: Task<Void, Never>?
    private let session: NetworkSession
    private let defaults: UserDefaults

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Initialization

    init(session: NetworkSession? = nil, defaults: UserDefaults = .standard) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 5
            config.timeoutIntervalForResource = 10
            self.session = URLSession(configuration: config)
        }
        self.defaults = defaults

        // Load saved address
        if let saved = defaults.string(forKey: "controllerIP"), !saved.isEmpty {
            controllerAddress = saved
            startPolling()
        }
    }

    // MARK: - Public Methods

    func updateControllerAddress(_ address: String) {
        defaults.set(address, forKey: "controllerIP")

        pollingTask?.cancel()
        if !address.isEmpty {
            startPolling()
        } else {
            isConnected = false
        }
    }

    func toggleHeater() async {
        let newState = !isHeating
        await setHeaterState(newState)
    }

    func setHeaterState(_ enabled: Bool) async {
        guard !controllerAddress.isEmpty else { return }

        let endpoint = "\(baseURL)/heater"
        guard let url = URL(string: endpoint) else {
            lastError = "Invalid controller address"
            return
        }

        lastError = nil
        isCommandInFlight = true
        defer { isCommandInFlight = false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["state": enabled ? 1 : 0]
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            lastError = "Failed to encode request: \(error.localizedDescription)"
            return
        }

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    isHeating = enabled
                } else {
                    lastError = "Heater command failed (HTTP \(httpResponse.statusCode))"
                }
            }
        } catch {
            lastError = "Failed to set heater state: \(error.localizedDescription)"
        }
    }

    func setTargetTemperature(_ temp: Double) async {
        guard !controllerAddress.isEmpty else { return }

        let endpoint = "\(baseURL)/target"
        guard let url = URL(string: endpoint) else {
            lastError = "Invalid controller address"
            return
        }

        lastError = nil
        isCommandInFlight = true
        defer { isCommandInFlight = false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["temperature": temp]
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            lastError = "Failed to encode request: \(error.localizedDescription)"
            return
        }

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    targetTemperature = temp
                } else {
                    lastError = "Temperature command failed (HTTP \(httpResponse.statusCode))"
                }
            }
        } catch {
            lastError = "Failed to set target temperature: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    private var baseURL: String {
        "http://\(controllerAddress)"
    }

    private func startPolling() {
        pollingTask = Task {
            var backoff: Duration = .seconds(2)
            while !Task.isCancelled {
                await fetchStatus()
                backoff = isConnected ? .seconds(2) : min(backoff * 2, .seconds(30))
                try? await Task.sleep(for: backoff)
            }
        }
    }

    private func fetchStatus() async {
        guard !controllerAddress.isEmpty else { return }

        let endpoint = "\(baseURL)/status"
        guard let url = URL(string: endpoint) else { return }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isConnected = false
                return
            }

            let status = try JSONDecoder().decode(SaunaStatus.self, from: data)
            currentTemperature = status.currentTemperature
            targetTemperature = status.targetTemperature
            isHeating = status.isHeating
            firmwareVersion = status.firmwareVersion
            isConnected = true
            lastError = nil

        } catch {
            isConnected = false
            print("Failed to fetch status: \(error.localizedDescription)")
        }
    }
}
