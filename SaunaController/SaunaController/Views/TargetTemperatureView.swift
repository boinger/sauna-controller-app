//
//  TargetTemperatureView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI

struct TargetTemperatureView: View {
    @Binding var targetTemp: Double

    private let minTemp: Double = 40
    private let maxTemp: Double = 100

    var body: some View {
        VStack(spacing: 12) {
            Text("Target Temperature")
                .font(.headline)

            HStack(spacing: 24) {
                Button {
                    targetTemp = max(targetTemp - 5, minTemp)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }
                .disabled(targetTemp <= minTemp)
                .accessibilityLabel("Decrease temperature")
                .accessibilityHint("Decreases target by 5 degrees")

                Text("\(Int(targetTemp))°C")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .frame(width: 100)
                    .accessibilityLabel("Target temperature \(Int(targetTemp)) degrees")

                Button {
                    targetTemp = min(targetTemp + 5, maxTemp)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.red)
                }
                .disabled(targetTemp >= maxTemp)
                .accessibilityLabel("Increase temperature")
                .accessibilityHint("Increases target by 5 degrees")
            }

            Slider(value: $targetTemp, in: minTemp...maxTemp, step: 5)
                .tint(.orange)
                .padding(.horizontal)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TargetTemperatureView(targetTemp: .constant(75))
}
