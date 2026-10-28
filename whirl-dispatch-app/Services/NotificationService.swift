//
//  NotificationService.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-27.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private(set) var isAuthorized: Bool = false

    override private init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            return granted
        } catch {
            print("[NOTIFICATIONS ERROR] Authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleDispatchNotification(
        workOrderNumber: String,
        title: String,
        facilityName: String,
        leadTechName: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Dispatch Dispatched: \(workOrderNumber)"
        content.subtitle = facilityName
        content.body = "Assigned Lead: \(leadTechName). \(title)"
        content.sound = .default
        content.badge = 1

        // Immediate trigger within 1 second for visible banner presentation
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "dispatch-\(workOrderNumber)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("[NOTIFICATIONS ERROR] Failed to schedule notification request: \(error.localizedDescription)")
            }
        }
    }

    func scheduleGeofenceBreachNotification(
        facilityName: String,
        distanceMeters: Double,
        radiusMeters: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Geofence Perimeter Warning"
        content.subtitle = facilityName
        content.body = "You have exited the designated site boundary (\(Int(distanceMeters))m from site, perimeter is \(Int(radiusMeters))m). Please return to the site or pause your shift."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "geofence-breach-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("[NOTIFICATIONS ERROR] Failed to schedule geofence breach notification: \(error.localizedDescription)")
            }
        }
    }

    // Deliver notification banner even while the application is active in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
