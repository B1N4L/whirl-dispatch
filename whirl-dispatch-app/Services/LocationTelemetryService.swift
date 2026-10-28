//
//  LocationTelemetryService.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-28.
//

import Foundation
import UIKit
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationTelemetryService {
    static let shared = LocationTelemetryService()

    private(set) var isTrackingActive: Bool = false
    private(set) var activeWorkOrderId: String? = nil
    private(set) var lastTransmittedAt: Date? = nil
    private(set) var lastResponse: RecordTelemetryResponse? = nil
    private(set) var lastErrorMessage: String? = nil

    private var heartbeatTimer: Timer? = nil
    private let apiService: APIService
    private let locationManager: LocationManager
    private let offlineManager: OfflineModeManager

    var transmitIntervalSeconds: TimeInterval = 30.0

    init(
        apiService: APIService = .shared,
        locationManager: LocationManager = .shared,
        offlineManager: OfflineModeManager = .shared
    ) {
        self.apiService = apiService
        self.locationManager = locationManager
        self.offlineManager = offlineManager
    }

    // Start background telemetry transmission for an active shift
    func startTracking(workOrderId: String) {
        if isTrackingActive && activeWorkOrderId == workOrderId {
            return
        }

        self.activeWorkOrderId = workOrderId
        self.isTrackingActive = true
        self.lastErrorMessage = nil

        UIDevice.current.isBatteryMonitoringEnabled = true
        locationManager.startUpdating()

        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: transmitIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.transmitTelemetry()
            }
        }

        Task { @MainActor [weak self] in
            await self?.transmitTelemetry()
        }
    }

    // Stop telemetry transmission when shift ends or technician logs out
    func stopTracking() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        isTrackingActive = false
        activeWorkOrderId = nil
    }

    // Transmit immediate GPS coordinates and device battery telemetry
    func transmitTelemetry() async {
        guard isTrackingActive, let workOrderId = activeWorkOrderId else { return }

        // Skip network transmission if plant room offline mode is active
        if offlineManager.isPlantRoomOffline {
            return
        }

        let coord = locationManager.effectiveCoordinate
        let rawAccuracy = locationManager.currentLocation?.horizontalAccuracy ?? 5.0
        let accuracy = rawAccuracy > 0 ? rawAccuracy : 5.0

        let rawBattery = UIDevice.current.batteryLevel
        let batteryLevel: Int? = rawBattery >= 0 ? Int(round(rawBattery * 100)) : nil

        do {
            let res: RecordTelemetryResponse = try await apiService.send(
                .sendTelemetry(
                    workOrderId: workOrderId,
                    lat: coord.latitude,
                    lng: coord.longitude,
                    accuracy: accuracy,
                    batteryLevel: batteryLevel
                )
            )
            self.lastResponse = res
            self.lastTransmittedAt = Date()
            self.lastErrorMessage = nil
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
    }
}
