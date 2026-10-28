//
//  ShiftWidgetIntents.swift
//  whirl-dispatch-widget
//
//  Created by Binal on 2026-10-28.
//

import AppIntents
import SwiftUI

// clock in button trigger
struct ClockInAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock In to Shift"
    static var description = IntentDescription("Launches WhirlDispatch to verify geofence and begin technician on-site shift.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}


// break pause toggle trigger
struct ToggleBreakAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Shift Break"
    static var description = IntentDescription("Pauses or resumes the ongoing technician on-site shift.")

    @MainActor
    func perform() async throws -> some IntentResult {
        var snapshot = ShiftWidgetSnapshot.load()
        if snapshot.isClockedIn {
            snapshot.isOnBreak.toggle()
            snapshot.pendingBreakSync = true
            snapshot.lastUpdated = Date()
            snapshot.save()
            ShiftWidgetSnapshot.reloadWidget()
        }
        return .result()
    }
}


// clock out button trigger
struct ClockOutAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock Out of Shift"
    static var description = IntentDescription("Opens WhirlDispatch to complete shift checkout and sync work order logs.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
