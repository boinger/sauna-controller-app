//
//  ContentView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var saunaManager: SaunaManager
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Temperature Display
                TemperatureGaugeView(
                    currentTemp: saunaManager.currentTemperature,
                    targetTemp: saunaManager.targetTemperature
                )

                // Target Temperature Control
                TargetTemperatureView(
                    displayTemp: saunaManager.targetTemperature,
                    onChanged: { newValue in
                        debounceTask?.cancel()
                        debounceTask = Task {
                            try? await Task.sleep(for: .milliseconds(300))
                            guard !Task.isCancelled else { return }
                            await saunaManager.setTargetTemperature(newValue)
                        }
                    }
                )

                // Power Control
                PowerControlView(
                    isHeating: saunaManager.isHeating,
                    onToggle: {
                        Task {
                            await saunaManager.toggleHeater()
                        }
                    }
                )
                .disabled(saunaManager.isCommandInFlight)

                Spacer()
            }
            .padding()
            .navigationTitle("Sauna")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { saunaManager.lastError != nil },
                    set: { if !$0 { saunaManager.lastError = nil } }
                )
            ) {
                Button("OK") { saunaManager.lastError = nil }
            } message: {
                Text(saunaManager.lastError ?? "")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SaunaManager())
}
