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

        // parts markup = 200 * 0.20 = 40; parts with markup = 240
        #expect(billingVM.partsMarkupAmount == 40.0)
        #expect(billingVM.partsWithMarkup == 240.0)

        // subtotal = 320 + 240 + 50 = 610
        #expect(billingVM.subtotalBeforeTax == 610.0)

        // tax = 610 * 0.10 = 61
        #expect(billingVM.calculatedTaxAmount == 61.0)

        // grand total = 610 + 61 = 671
        #expect(billingVM.grandTotal == 671.0)
        #expect(billingVM.formattedGrandTotal.contains("671.00"))
    }


    @Test func testBillingDynamicMarkupSliderAdjustment() throws {
        let billingVM = BillingViewModel()
        billingVM.laborHours = 5.0
        billingVM.hourlyRate = 100.0
        billingVM.partsSubtotal = 300.0
        billingVM.partsMarkupPercent = 15.0
        billingVM.equipmentFee = 0.0
        billingVM.taxPercent = 0.0

        #expect(billingVM.partsWithMarkup == 345.0)
        #expect(billingVM.grandTotal == 845.0)

        // clerk increases parts markup to 30%
        billingVM.partsMarkupPercent = 30.0
        #expect(billingVM.partsMarkupAmount == 90.0)
        #expect(billingVM.partsWithMarkup == 390.0)
        #expect(billingVM.grandTotal == 890.0)
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
