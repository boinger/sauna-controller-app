//
//  PowerControlView.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI

struct PowerControlView: View {
    let isHeating: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isHeating ? "flame.fill" : "flame")
                    .font(.title2)

                Text(isHeating ? "Heating" : "Start Sauna")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isHeating ? Color.red : Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .accessibilityLabel(isHeating ? "Stop heating" : "Start sauna")
        .accessibilityHint(isHeating ? "Turns off the sauna heater" : "Turns on the sauna heater")
    }
}

#Preview("Off State") {
    PowerControlView(isHeating: false, onToggle: {})
}

#Preview("Heating State") {
    PowerControlView(isHeating: true, onToggle: {})
}
