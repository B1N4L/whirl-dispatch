//
//  ShiftTimelineProvider.swift
//  whirl-dispatch-widget
//
//  Created by Binal on 2026-10-28.
//

import WidgetKit
import SwiftUI

struct ShiftTimelineProvider: TimelineProvider {
    typealias Entry = ShiftWidgetEntry

    func placeholder(in context: Context) -> ShiftWidgetEntry {
        ShiftWidgetEntry(
            date: Date(),
            snapshot: ShiftWidgetSnapshot(
                isClockedIn: true,
                isOnBreak: false,
                clockInDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
                totalBreakSeconds: 900,
                activeWorkOrderNumber: "WO-2026-0842",
                activeWorkOrderTitle: "Chiller Overhaul & Compressor Coil Inspection",
                activeFacilityName: "Colombo Central Data Center",
                todayTotalHours: 5.4,
                lastUpdated: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftWidgetEntry) -> Void) {
        let snapshot = ShiftWidgetSnapshot.load()
        let entry = ShiftWidgetEntry(date: Date(), snapshot: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftWidgetEntry>) -> Void) {
        let snapshot = ShiftWidgetSnapshot.load()
        let currentDate = Date()
        let entry = ShiftWidgetEntry(date: currentDate, snapshot: snapshot)

        // schedule next refresh in 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
