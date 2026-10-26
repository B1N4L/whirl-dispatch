//
//  WorkOrderCardView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-18.
//

import SwiftUI

extension WorkOrderPriority {
    var toPriorityLevel: PriorityLevel {
        switch self {
        case .criticalEmergency: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}

extension WorkOrderStatus {
    var toStatusType: WorkOrderStatusType {
        switch self {
        case .dispatched: return .dispatched
        case .enRoute: return .traveling
        case .onSiteActive, .unacknowledgedBreak, .awaitingPartsApproval: return .inProgress
        case .completed, .billed: return .completed
        case .cancelled: return .cancelled
        }
    }
}


struct WorkOrderCardView: View {
    let order: WorkOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // top header row: order number, priority, and current state
            HStack(alignment: .center) {
                Text(order.workOrderNumber)
                    .font(.appMonoCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                PriorityBadge(priority: order.priority.toPriorityLevel)
                StatusBadge(status: order.status.toStatusType)
            }


            // job title
            Text(order.title)
                .font(.appHeadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)


            // facility and plant room info
            if let facility = order.facility {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.accentBlue)

                        Text(facility.displayName)
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(facility.address)
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }


            Divider()
                .padding(.vertical, 2)


            // bottom footer row: scheduled window and equipment
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(formatScheduledTime(order.scheduledStartTime))
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if order.isEmergency {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.caption2)
                            .foregroundColor(Color.statusRed)
                        Text("SLA: 2h")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.statusRed)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(order.isEmergency ? Color.statusRed.opacity(0.3) : Color.surfaceBorder.opacity(0.6), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(order.workOrderNumber): \(order.title). Priority: \(order.priority.rawValue). Status: \(order.status.rawValue). Facility: \(order.facility?.displayName ?? "Unknown facility")")
        .accessibilityHint("Double tap to open work order details")
    }


    // simple date parser for scheduled timestamp
    private func formatScheduledTime(_ isoString: String) -> String {
      let isoFormatter = ISO8601DateFormatter()
      if let date = isoFormatter.date(from: isoString) {
          let displayFormatter = DateFormatter()
          displayFormatter.dateFormat = "MMM d, h:mm a"
          return displayFormatter.string(from: date)
      }
      return isoString
    }
}
