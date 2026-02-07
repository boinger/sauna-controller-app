//
//  SettingsView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var saunaManager: SaunaManager
    @AppStorage("maxSessionMinutes") private var maxSessionMinutes: Int = 60

    var body: some View {
        Form {
            Section("Controller") {
                HStack {
                    Text("IP Address")
                    Spacer()
                    TextField("192.168.1.x", text: $saunaManager.controllerAddress)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(saunaManager.isConnected ? .green : .red)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(saunaManager.isConnected ? "Connected" : "Disconnected")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Connection status: \(saunaManager.isConnected ? "Connected" : "Disconnected")")
                }
            }

            Section("Safety") {
                Stepper("Max Session: \(maxSessionMinutes) min", value: $maxSessionMinutes, in: 15...120, step: 15)
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                LabeledContent("Firmware", value: saunaManager.firmwareVersion ?? "Unknown")
            }
        }
        .navigationTitle("Settings")
        .onChange(of: saunaManager.controllerAddress) { _, newValue in
            saunaManager.updateControllerAddress(newValue)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SaunaManager())
    }
}
