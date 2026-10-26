//
//  CalendarSyncService.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-26.
//

import Foundation
import EventKit
import Observation

@Observable
final class CalendarSyncService: @unchecked Sendable {
    static let shared = CalendarSyncService()

    var isAuthorized: Bool = false
    var lastSyncedEventId: String? = nil
    var syncErrorMessage: String? = nil
    var syncedWorkOrderIds: Set<String> = []

    private let eventStore = EKEventStore()
    private let userDefaultsKey = "WhirlDispatch_SyncedCalendarEvents"


    init() {
        checkCurrentAuthorization()
        loadPersistedSyncedIds()
    }


    func checkCurrentAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            self.isAuthorized = (status == .fullAccess || status == .writeOnly)
        } else {
            self.isAuthorized = (status == .authorized)
        }
    }


    // request permissions from technician
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.isAuthorized = granted
                }
                return granted
            } catch {
                await MainActor.run {
                    self.syncErrorMessage = error.localizedDescription
                }
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    DispatchQueue.main.async {
                        self?.isAuthorized = granted
                        if let err = error {
                            self?.syncErrorMessage = err.localizedDescription
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }


    // sync single dispatched work order to calendar
    func syncWorkOrderToCalendar(_ workOrder: WorkOrder) async throws -> String {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else {
                throw NSError(
                    domain: "WhirlDispatchCalendar",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "Calendar access was denied. Enable WhirlDispatch in iOS Settings."]
                )
            }
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw NSError(
                domain: "WhirlDispatchCalendar",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No default calendar found on device."]
            )
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "[WhirlDispatch] \(workOrder.title) - \(workOrder.workOrderNumber)"

        // parse dates or fallback to scheduled dispatch slot
        let startDate = parseDate(workOrder.scheduledStartTime) ?? Date().addingTimeInterval(3600)
        let endDate = parseDate(workOrder.scheduledEndTime) ?? startDate.addingTimeInterval(7200)

        event.startDate = startDate
        event.endDate = endDate

        // detailed site instructions
        var notesContent = "WhirlDispatch Commercial HVAC Service Dispatch\n"
        notesContent += "Work Order: \(workOrder.workOrderNumber)\n"
        notesContent += "Priority: \(workOrder.priority.title)\n"
        notesContent += "Status: \(workOrder.status.label)\n"

        if let fac = workOrder.facility {
            notesContent += "\nFacility: \(fac.facilityName)\n"
            notesContent += "Company: \(fac.companyName)\n"
            notesContent += "Site Address: \(fac.address)\n"
            notesContent += "Site Contact: \(fac.contactPersonName) (\(fac.contactPhone))\n"
            event.location = "\(fac.facilityName), \(fac.address)"
        }

        notesContent += "\nScope of Work:\n\(workOrder.description)\n"
        event.notes = notesContent

        try eventStore.save(event, span: .thisEvent, commit: true)

        let eventIdentifier = event.eventIdentifier ?? UUID().uuidString
        await MainActor.run {
            self.lastSyncedEventId = eventIdentifier
            self.syncedWorkOrderIds.insert(workOrder.id)
            self.persistSyncedIds()
        }

        return eventIdentifier
    }


    func isOrderSynced(_ workOrderId: String) -> Bool {
        syncedWorkOrderIds.contains(workOrderId)
    }


    private func parseDate(_ dateStr: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFormatter.date(from: dateStr) {
            return d
        }

        let fallbackFormatter = ISO8601DateFormatter()
        if let d = fallbackFormatter.date(from: dateStr) {
            return d
        }

        let customFormatter = DateFormatter()
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return customFormatter.date(from: dateStr)
    }


    private func loadPersistedSyncedIds() {
        if let saved = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            self.syncedWorkOrderIds = Set(saved)
        }
    }

    private func persistSyncedIds() {
        UserDefaults.standard.set(Array(syncedWorkOrderIds), forKey: userDefaultsKey)
    }
}
