//
//  WidgetSyncManager.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-28.
//

import Foundation
import WidgetKit

@MainActor
final class WidgetSyncManager {
    static let shared = WidgetSyncManager()

    private init() {}

    // sync active technician shift state to widget snapshot
    func syncShift(
        isClockedIn: Bool,
        isOnBreak: Bool,
        clockInDate: Date?,
        totalBreakSeconds: Int,
        workOrderNumber: String?,
        workOrderTitle: String?,
        facilityName: String?,
        todayTotalHours: Double
    ) {
        let snapshot = ShiftWidgetSnapshot(
            isClockedIn: isClockedIn,
            isOnBreak: isOnBreak,
            clockInDate: clockInDate,
            totalBreakSeconds: totalBreakSeconds,
            activeWorkOrderNumber: workOrderNumber,
            activeWorkOrderTitle: workOrderTitle,
            activeFacilityName: facilityName,
            todayTotalHours: todayTotalHours,
            lastUpdated: Date()
        )
        snapshot.save()
        ShiftWidgetSnapshot.reloadWidget()
    }

    // clear active shift state when clocking out
    func syncClockOut(todayTotalHours: Double) {
        let snapshot = ShiftWidgetSnapshot(
            isClockedIn: false,
            isOnBreak: false,
            clockInDate: nil,
            totalBreakSeconds: 0,
            activeWorkOrderNumber: nil,
            activeWorkOrderTitle: nil,
            activeFacilityName: nil,
            todayTotalHours: todayTotalHours,
            lastUpdated: Date()
        )
        snapshot.save()
        ShiftWidgetSnapshot.reloadWidget()
    }
}
