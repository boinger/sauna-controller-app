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
    @AppStorage("controllerIP") private var controllerIP: String = ""

    var body: some View {
        Form {
            Section("Controller") {
                HStack {
                    Text("IP Address")
                    Spacer()
                    TextField("192.168.1.x", text: $controllerIP)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(saunaManager.isConnected ? .green : .red)
                            .frame(width: 10, height: 10)
                        Text(saunaManager.isConnected ? "Connected" : "Disconnected")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Safety") {
                Stepper("Max Session: \(maxSessionMinutes) min", value: $maxSessionMinutes, in: 15...120, step: 15)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Firmware", value: saunaManager.firmwareVersion ?? "Unknown")
            }
        }
        .navigationTitle("Settings")
        .onChange(of: controllerIP) { _, newValue in
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
