//
//  SecondaryButton.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-04.
//

import SwiftUI
import UIKit

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isDestructive: Bool = false
    let action: () -> Void


    var body: some View {
        Button(action: {
            // light haptic for secondary action
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()

            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.appHeadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(isDestructive ? Color.statusRed : Color.brandNavy)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDestructive ? Color.statusRed.opacity(0.5) : Color.brandNavy.opacity(0.3), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            )
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}


#Preview {
    VStack(spacing: 12) {
        SecondaryButton(title: "Pause Shift for Lunch", icon: "pause.fill") {}
        SecondaryButton(title: "Cancel Dispatch", icon: "xmark", isDestructive: true) {}
    }
    .padding()
}
