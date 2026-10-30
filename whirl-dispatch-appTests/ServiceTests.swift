//
//  ServiceTests.swift
//  whirl-dispatch-appTests
//
//  Created by Binal on 2026-10-26.
//

import Testing
import Foundation
import CoreLocation
@testable import whirl_dispatch_app

@MainActor
struct ServiceTests {

    // MARK: - Geofencing & Anti-Ghost Clocking Tests

    @Test func testGeofenceZeroDistanceForIdenticalCoordinates() throws {
        let geofence = GeofenceService.shared
        let point = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)

        let distance = geofence.calculateDistance(from: point, to: point)
        #expect(distance < 0.001)
    }


    @Test func testGeofenceInsidePerimeterEvaluation() throws {
        let geofence = GeofenceService.shared
        let facilityCenter = CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428)

        // offset by approximately 50 meters north
        let technicianLocation = CLLocationCoordinate2D(latitude: 6.93485, longitude: 79.8428)

        let evaluation = geofence.evaluate(
            userCoordinate: technicianLocation,
            facilityCoordinate: facilityCenter,
            radiusMeters: 150.0
        )

        #expect(evaluation.isInside == true)
        #expect(evaluation.distanceMeters < 150.0)
        #expect(evaluation.formattedDistance.hasSuffix("m"))
    }


    @Test func testGeofenceOutsidePerimeterAntiGhostEnforcement() throws {
        let geofence = GeofenceService.shared
        let facilityCenter = CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428)

        // technician is 2.5 km away in Kollupitiya
        let remoteLocation = CLLocationCoordinate2D(latitude: 6.9120, longitude: 79.8507)

        let evaluation = geofence.evaluate(
            userCoordinate: remoteLocation,
            facilityCoordinate: facilityCenter,
            radiusMeters: 150.0
        )

        #expect(evaluation.isInside == false)
        #expect(evaluation.distanceMeters > 150.0)
        #expect(evaluation.formattedDistance.contains("km"))
    }


    // MARK: - Billing Cost Engine Calculations

    @Test func testBillingCostEstimationMathematicalFormulas() throws {
        let billingVM = BillingViewModel()
        billingVM.laborHours = 4.0
        billingVM.hourlyRate = 80.0
        billingVM.partsSubtotal = 200.0
        billingVM.partsMarkupPercent = 20.0
        billingVM.equipmentFee = 50.0
        billingVM.taxPercent = 10.0

        // labor = 4 * 80 = 320
        #expect(billingVM.laborSubtotal == 320.0)
        #expect(billingVM.formattedLaborSubtotal.contains("320.00"))

        // direct cost base = 320 + 200 = 520
        #expect(billingVM.directCostSubtotal == 520.0)

        // markup = 520 * 0.20 = 104
        #expect(billingVM.markupAmount == 104.0)
        #expect(billingVM.partsMarkupAmount == 104.0)

        // subtotal before tax = 520 + 104 + 50 = 674
        #expect(billingVM.subtotalBeforeTax == 674.0)

        // tax = 674 * 0.10 = 67.4
        #expect(billingVM.calculatedTaxAmount == 67.4)

        // grand total = 674 + 67.4 = 741.4
        #expect(billingVM.grandTotal == 741.4)
        #expect(billingVM.formattedGrandTotal.contains("741.40"))
    }


    @Test func testBillingDynamicMarkupSliderAdjustment() throws {
        let billingVM = BillingViewModel()
        billingVM.laborHours = 5.0
        billingVM.hourlyRate = 100.0
        billingVM.partsSubtotal = 300.0
        billingVM.partsMarkupPercent = 15.0
        billingVM.equipmentFee = 0.0
        billingVM.taxPercent = 0.0

        // labor = 500, parts = 300, direct cost base = 800
        // markup 15% = 800 * 0.15 = 120
        #expect(billingVM.directCostSubtotal == 800.0)
        #expect(billingVM.markupAmount == 120.0)
        #expect(billingVM.grandTotal == 920.0)

        // clerk increases markup to 30%
        billingVM.partsMarkupPercent = 30.0
        // markup 30% = 800 * 0.30 = 240
        #expect(billingVM.markupAmount == 240.0)
        #expect(billingVM.grandTotal == 1040.0)
    }


    // MARK: - Keychain Security Storage

    @Test func testKeychainTokenSaveReadAndClearLifecycle() throws {
        let keychain = KeychainManager.shared
        let testToken = "test_jwt_bearer_token_whirldispatch_8849"

        keychain.saveToken(testToken)
        let retrieved = keychain.getToken()
        #expect(retrieved == testToken)

        keychain.clearToken()
        let cleared = keychain.getToken()
        #expect(cleared == nil)
    }


    // MARK: - Plant Room Offline Mode Rules

    @Test func testPlantRoomOfflineModeSiteValidation() throws {
        let offline = OfflineModeManager.shared
        offline.isPlantRoomOffline = false

        let dispatchedOrder = WorkOrder(
            id: "wo-offline-test",
            workOrderNumber: "WO-OFF-01",
            clientFacilityId: "fac-1",
            supervisorId: "sup-1",
            leadTechnicianId: "tech-1",
            assignedFleetAssetId: nil,
            title: "Plant Room Test",
            description: "Testing offline restriction",
            priority: .high,
            status: .dispatched,
            scheduledStartTime: "2026-10-26T10:00:00Z",
            scheduledEndTime: "2026-10-26T12:00:00Z",
            actualStartTime: nil,
            actualEndTime: nil,
            facility: nil
        )

        // attempting to toggle when dispatched (not on-site active)
        let blockedResult = offline.setPlantRoomOffline(enabled: true, for: dispatchedOrder)
        #expect(blockedResult == false)
        #expect(offline.isPlantRoomOffline == false)
        #expect(offline.restrictionErrorMessage != nil)

        // attempting with nil work order
        let nilResult = offline.setPlantRoomOffline(enabled: true, for: nil)
        #expect(nilResult == false)
        #expect(offline.isPlantRoomOffline == false)

        var onSiteOrder = dispatchedOrder
        onSiteOrder.status = .onSiteActive

        // attempting after arriving and clocking in on-site
        let activeResult = offline.setPlantRoomOffline(enabled: true, for: onSiteOrder)
        #expect(activeResult == true)
        #expect(offline.isPlantRoomOffline == true)
        #expect(offline.restrictionErrorMessage == nil)

        // switching back online
        let onlineResult = offline.setPlantRoomOffline(enabled: false, for: onSiteOrder)
        #expect(onlineResult == true)
        #expect(offline.isPlantRoomOffline == false)
    }


    // MARK: - Location Simulation & Departure Tests

    @Test func testLocationManagerSimulationCycle() throws {
        let locationManager = LocationManager.shared
        let facilityCoord = CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428)

        // 1. Simulate arrival inside facility
        locationManager.simulateArrival(at: facilityCoord)
        #expect(locationManager.isSimulatedLocationActive == true)
        #expect(locationManager.effectiveCoordinate.latitude == facilityCoord.latitude)
        #expect(locationManager.effectiveCoordinate.longitude == facilityCoord.longitude)

        let evalInside = GeofenceService.shared.evaluate(
            userCoordinate: locationManager.effectiveCoordinate,
            facilityCoordinate: facilityCoord,
            radiusMeters: 150.0
        )
        #expect(evalInside.isInside == true)
        #expect(evalInside.distanceMeters < 1.0)

        // 2. Simulate departure outside facility geofence (~660m away)
        locationManager.simulateDeparture(from: facilityCoord)
        #expect(locationManager.isSimulatedLocationActive == true)

        let evalOutside = GeofenceService.shared.evaluate(
            userCoordinate: locationManager.effectiveCoordinate,
            facilityCoordinate: facilityCoord,
            radiusMeters: 150.0
        )
        #expect(evalOutside.isInside == false)
        #expect(evalOutside.distanceMeters > 500.0)

        // 3. Reset simulation back to physical GPS
        locationManager.resetSimulation()
        #expect(locationManager.isSimulatedLocationActive == false)
    }

    @Test func testLocationTelemetryGeofenceBreachEvaluationAndCooldown() throws {
        let telemetryService = LocationTelemetryService.shared
        let facilityCoord = CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428)
        let remoteCoord = CLLocationCoordinate2D(latitude: 6.9120, longitude: 79.8507)

        telemetryService.startTracking(
            workOrderId: "wo-test-breach",
            facilityName: "Test Facility",
            facilityCoordinate: facilityCoord,
            geofenceRadius: 150.0
        )

        #expect(telemetryService.isTrackingActive == true)
        #expect(telemetryService.activeFacilityName == "Test Facility")

        // 1. When inside geofence, no breach is triggered
        telemetryService.checkGeofenceBreach(userCoordinate: facilityCoord, isOnBreak: false)
        #expect(telemetryService.wasInsideGeofence == true)
        #expect(telemetryService.lastBreachNotificationDate == nil)

        // 2. When outside geofence during work shift, breach notification timestamp is set
        telemetryService.checkGeofenceBreach(userCoordinate: remoteCoord, isOnBreak: false)
        #expect(telemetryService.wasInsideGeofence == false)
        let firstBreachDate = try #require(telemetryService.lastBreachNotificationDate)

        // 3. Repeated call immediately within 5-minute cooldown does not advance breach notification timestamp
        telemetryService.checkGeofenceBreach(userCoordinate: remoteCoord, isOnBreak: false)
        #expect(telemetryService.lastBreachNotificationDate == firstBreachDate)

        // 4. When on break, breach evaluation is suppressed
        telemetryService.stopTracking()
        telemetryService.startTracking(
            workOrderId: "wo-test-breach",
            facilityName: "Test Facility",
            facilityCoordinate: facilityCoord,
            geofenceRadius: 150.0
        )
        telemetryService.checkGeofenceBreach(userCoordinate: remoteCoord, isOnBreak: true)
        #expect(telemetryService.lastBreachNotificationDate == nil)

        telemetryService.stopTracking()
        #expect(telemetryService.isTrackingActive == false)
    }

    @Test func testOrphanedActiveAttendanceCleanup() async throws {
        let storage = OfflineStorageService.shared
        let testRecord = AttendanceRecord(
            id: UUID().uuidString,
            workOrderId: "wo-test-cleanup",
            technicianId: "tech-test-cleanup",
            clockInTimestamp: ISO8601DateFormatter().string(from: Date()),
            clockOutTimestamp: nil,
            totalBillableSeconds: 0,
            totalBreakSeconds: 0,
            sessionStatus: .activeOnSite
        )

        // Save active record with isSyncPending == false (simulating synced session that closed on server)
        await storage.upsertAttendance(testRecord, isSyncPending: false)

        let activeBefore = await storage.fetchActiveCachedAttendance(technicianId: "tech-test-cleanup")
        #expect(activeBefore != nil)
        #expect(activeBefore?.id == testRecord.id)

        // Run cleanup
        await storage.clearOrphanedActiveAttendance(technicianId: "tech-test-cleanup")

        let activeAfter = await storage.fetchActiveCachedAttendance(technicianId: "tech-test-cleanup")
        #expect(activeAfter == nil)
    }
}
