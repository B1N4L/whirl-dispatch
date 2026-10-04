//
//  StatusBadge.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-04.
//

import SwiftUI

enum WorkOrderStatusType: String, CaseIterable {
    case pending = "pending"
    case dispatched = "dispatched"
    case traveling = "traveling"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"


    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .dispatched: return "Dispatched"
        case .traveling: return "Traveling"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .dispatched: return "arrow.right.circle.fill"
        case .traveling: return "car.fill"
        case .inProgress: return "bolt.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return Color.statusGray
        case .dispatched: return Color.accentBlue
        case .traveling: return Color.accentBlue
        case .inProgress: return Color.statusAmber
        case .completed: return Color.statusGreen
        case .cancelled: return Color.statusRed
        }
    }
}


struct StatusBadge: View {
    let status: WorkOrderStatusType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(status.displayName)
                .font(.appCaption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(status.color)
        .background(
            Capsule()
                .fill(status.color.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.25), lineWidth: 0.8)
        )
        .accessibilityLabel("Status: \(status.displayName)")
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(WorkOrderStatusType.allCases, id: \.self) { st in
            StatusBadge(status: st)
        }
    }
    .padding()
}
