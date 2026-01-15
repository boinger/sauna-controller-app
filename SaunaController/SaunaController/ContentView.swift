//
//  ContentView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var saunaManager: SaunaManager

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
                    targetTemp: $saunaManager.targetTemperature
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
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SaunaManager())
}
