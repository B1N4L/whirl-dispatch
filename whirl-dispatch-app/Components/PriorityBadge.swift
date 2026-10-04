//
//  PriorityBadge.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-04.
//

import SwiftUI

enum PriorityLevel: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"


    var title: String {
        switch self {
        case .critical: return "Emergency"
        case .high: return "High Priority"
        case .medium: return "Standard"
        case .low: return "Low"
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        case .medium: return "equal.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .critical: return Color.statusRed
        case .high: return Color.statusAmber
        case .medium: return Color.accentBlue
        case .low: return Color.statusGray
        }
    }
}


struct PriorityBadge: View {
    let priority: PriorityLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
                .font(.system(size: 10, weight: .bold))
            Text(priority.title)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .foregroundColor(priority.tintColor)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(priority.tintColor.opacity(0.12))
        )
        .accessibilityLabel("Priority: \(priority.title)")
    }
}


#Preview {
    HStack {
        PriorityBadge(priority: .critical)
        PriorityBadge(priority: .high)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .low)
    }
    .padding()
}
