//
//  SaunaManager.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import Foundation
import Combine

/// Manages communication with the ESP32 sauna controller
@MainActor
class SaunaManager: ObservableObject {
    // MARK: - Published State

    @Published var currentTemperature: Double = 20.0
    @Published var targetTemperature: Double = 75.0
    @Published var isHeating: Bool = false
    @Published var isConnected: Bool = false
    @Published var firmwareVersion: String?

    // MARK: - Private Properties

    private var controllerAddress: String = ""
    private var pollingTask: Task<Void, Never>?
    private let session: URLSession

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)

        // Load saved address
        if let saved = UserDefaults.standard.string(forKey: "controllerIP"), !saved.isEmpty {
            controllerAddress = saved
            startPolling()
        }
    }

    // MARK: - Public Methods

    func updateControllerAddress(_ address: String) {
        controllerAddress = address
        UserDefaults.standard.set(address, forKey: "controllerIP")

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
        guard let url = URL(string: endpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["state": enabled ? 1 : 0]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                isHeating = enabled
            }
        } catch {
            print("Failed to set heater state: \(error)")
        }
    }

    func setTargetTemperature(_ temp: Double) async {
        guard !controllerAddress.isEmpty else { return }

        let endpoint = "\(baseURL)/target"
        guard let url = URL(string: endpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["temperature": temp]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                targetTemperature = temp
            }
        } catch {
            print("Failed to set target temperature: \(error)")
        }
    }

    // MARK: - Private Methods

    private var baseURL: String {
        "http://\(controllerAddress)"
    }

    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchStatus()
                try? await Task.sleep(for: .seconds(2))
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

        } catch {
            isConnected = false
            print("Failed to fetch status: \(error)")
        }
    }
}

// MARK: - Response Models

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
