//
//  TargetTemperatureView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI

struct TargetTemperatureView: View {
    let displayTemp: Double
    let onChanged: (Double) -> Void

    @State private var localTemp: Double = 75.0

    private let minTemp: Double = 40
    private let maxTemp: Double = 100

    var body: some View {
        VStack(spacing: 12) {
            Text("Target Temperature")
                .font(.headline)

            HStack(spacing: 24) {
                Button {
                    localTemp = max(localTemp - 5, minTemp)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }
                .disabled(localTemp <= minTemp)
                .accessibilityLabel("Decrease temperature")
                .accessibilityHint("Decreases target by 5 degrees")

                Text("\(Int(localTemp))°C")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .frame(width: 100)
                    .accessibilityLabel("Target temperature \(Int(localTemp)) degrees")

                Button {
                    localTemp = min(localTemp + 5, maxTemp)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.red)
                }
                .disabled(localTemp >= maxTemp)
                .accessibilityLabel("Increase temperature")
                .accessibilityHint("Increases target by 5 degrees")
            }

            Slider(value: $localTemp, in: minTemp...maxTemp, step: 5)
                .tint(.orange)
                .padding(.horizontal)
                .onChange(of: localTemp) { _, newValue in
                    onChanged(newValue)
                }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            localTemp = displayTemp
        }
    }
}

#Preview {
    TargetTemperatureView(displayTemp: 75, onChanged: { _ in })
}
