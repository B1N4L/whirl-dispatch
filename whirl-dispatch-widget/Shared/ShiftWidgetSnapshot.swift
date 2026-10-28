//
//  ShiftWidgetSnapshot.swift
//  whirl-dispatch-widget
//
//  Created by Binal on 2026-10-28.
//

import Foundation
import WidgetKit

struct ShiftWidgetSnapshot: Codable, Sendable {
    var isClockedIn: Bool
    var isOnBreak: Bool
    var clockInDate: Date?
    var totalBreakSeconds: Int
    var activeWorkOrderNumber: String?
    var activeWorkOrderTitle: String?
    var activeFacilityName: String?
    var todayTotalHours: Double
    var lastUpdated: Date

    static let appGroupSuiteName = "group.com.whirldispatch.app"
    static let storageKey = "whirldispatch_shift_widget_snapshot"

    static var defaultSnapshot: ShiftWidgetSnapshot {
        ShiftWidgetSnapshot(
            isClockedIn: false,
            isOnBreak: false,
            clockInDate: nil,
            totalBreakSeconds: 0,
            activeWorkOrderNumber: nil,
            activeWorkOrderTitle: nil,
            activeFacilityName: nil,
            todayTotalHours: 0.0,
            lastUpdated: Date()
        )
    }

    // load snapshot from shared user defaults or fall back to standard
    static func load() -> ShiftWidgetSnapshot {
        let defaults = UserDefaults(suiteName: appGroupSuiteName) ?? UserDefaults.standard
        guard let data = defaults.data(forKey: storageKey) else {
            return .defaultSnapshot
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ShiftWidgetSnapshot.self, from: data)
        } catch {
            return .defaultSnapshot
        }
    }

    // save current snapshot to defaults
    func save() {
        let defaults = UserDefaults(suiteName: Self.appGroupSuiteName) ?? UserDefaults.standard
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            // ignore save failure
        }
    }

    // reload widget timeline
    static func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "TechnicianShiftWidget")
    }

    // computed formatted break time string
    var formattedBreakTime: String {
        let minutes = totalBreakSeconds / 60
        let seconds = totalBreakSeconds % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }

    // computed formatted today hours
    var formattedTodayHours: String {
        String(format: "%.1f hrs", todayTotalHours)
    }
}
