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
                    if targetTemp > minTemp {
                        targetTemp -= 5
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }
                .disabled(targetTemp <= minTemp)

                Text("\(Int(targetTemp))°C")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .frame(width: 100)

                Button {
                    if targetTemp < maxTemp {
                        targetTemp += 5
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.red)
                }
                .disabled(targetTemp >= maxTemp)
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
