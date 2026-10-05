//
//  FilterChip.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-05.
//

import SwiftUI
import UIKit

struct FilterChip: View {
    let title: String
    var count: Int? = nil
    var isSelected: Bool
    let onSelect: () -> Void


    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onSelect()
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.appSubheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.25) : Color(UIColor.tertiarySystemFill))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                Capsule()
                    .fill(isSelected ? Color.brandNavy : Color(UIColor.secondarySystemFill))
            )
        }
        .accessibilityLabel("\(title), \(count.map { "\($0) items" } ?? "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}


#Preview {
    HStack(spacing: 8) {
        FilterChip(title: "All", count: 12, isSelected: true) {}
        FilterChip(title: "Active", count: 4, isSelected: false) {}
        FilterChip(title: "Completed", count: 8, isSelected: false) {}
    }
    .padding()
}
