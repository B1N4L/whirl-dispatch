//
//  TechnicianShiftWidget.swift
//  whirl-dispatch-widget
//
//  Created by Binal on 2026-10-28.
//

import WidgetKit
import SwiftUI

struct TechnicianShiftWidget: Widget {
    let kind: String = "TechnicianShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftTimelineProvider()) { entry in
            ShiftWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Technician Shift Tracker")
        .description("Track active work order shift duration, take breaks, and manage clock in/out directly from your Home Screen.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ShiftWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ShiftWidgetEntry

    var body: some View {
        switch family {
        case .systemLarge:
            ShiftWidgetLargeView(snapshot: entry.snapshot)
        default:
            ShiftWidgetMediumView(snapshot: entry.snapshot)
        }
    }
}
