//
//  TemperatureGaugeView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI

struct TemperatureGaugeView: View {
    let currentTemp: Double
    let targetTemp: Double

    private var progress: Double {
        guard targetTemp > 0 else { return 0 }
        return min(currentTemp / targetTemp, 1.0)
    }

    private var temperatureColor: Color {
        switch currentTemp {
        case ..<40: .blue
        case 40..<60: .orange
        case 60..<80: .red
        default: .red.opacity(0.8)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 24)

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        temperatureColor,
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                // Temperature display
                VStack(spacing: 4) {
                    Text("\(Int(currentTemp))°")
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(temperatureColor)

                    Text("Current")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 240, maxHeight: 240)
            .aspectRatio(1, contentMode: .fit)

            // Target indicator
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.secondary)
                Text("Target: \(Int(targetTemp))°C")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Temperature gauge")
        .accessibilityValue("Current \(Int(currentTemp)) degrees, target \(Int(targetTemp)) degrees, \(Int(progress * 100)) percent")
    }
}

#Preview {
    TemperatureGaugeView(currentTemp: 65, targetTemp: 80)
}
