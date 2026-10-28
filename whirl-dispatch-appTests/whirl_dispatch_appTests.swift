//
//  whirl_dispatch_appTests.swift
//  whirl-dispatch-appTests
//
//  Created by Binal on 2026-10-04.
//

import Testing
import Foundation
import CoreLocation
@testable import whirl_dispatch_app

struct whirl_dispatch_appTests {

    @Test func testUserRoleDisplayNames() async throws {
        #expect(UserRole.technician.displayName == "Field Technician")
        #expect(UserRole.leadTechnician.displayName == "Lead Technician")
        #expect(UserRole.supervisor.displayName == "Operations Supervisor")
        #expect(UserRole.paymentClerk.displayName == "Payment Clerk")
    }


    @Test func testUserInitials() async throws {
        let user = User(
            id: "user-123",
            email: "sarath@example.com",
            fullName: "Sarath Perera",
            phone: "+94771234567",
            role: .technician,
            hourlyLaborRate: "50.00",
            biometricEnrolled: true,
            isActive: true,
            createdAt: nil
        )

        #expect(user.initials == "SP")
    }

    @Test func testFacilityCoordinateCalculation() async throws {
        let facility = Facility(
            id: "fac-1",
            companyName: "Apex Data Centers",
            facilityName: "Building B",
            address: "100 Server Way",
            latitude: 6.9271,
            longitude: 79.8612,
            geofenceRadius: 150.0,
            contactPersonName: "Nimal Silva",
            contactPhone: "+94770000000",
            contactEmail: nil,
            slaResponseHours: 4,
            contractHourlyRate: "75.00",
            partsMarkupPercent: "15.00"
        )

        #expect(facility.coordinate.latitude == 6.9271)
        #expect(facility.coordinate.longitude == 79.8612)
        #expect(facility.displayName == "Apex Data Centers - Building B")
    }


    @Test func testWorkOrderCanClockIn() async throws {
        let wo = WorkOrder(
            id: "wo-1",
            workOrderNumber: "WO-2026-001",
            clientFacilityId: "fac-1",
            supervisorId: "sup-1",
            leadTechnicianId: "lead-1",
            assignedFleetAssetId: nil,
            title: "Chiller Overhaul",
            description: "High head pressure alarm",
            priority: .criticalEmergency,
            status: .dispatched,
            scheduledStartTime: "2026-10-08T09:00:00Z",
            scheduledEndTime: "2026-10-08T17:00:00Z",
            actualStartTime: nil,
            actualEndTime: nil,
            facility: nil
        )

        #expect(wo.isEmergency == true)
        #expect(wo.canClockIn == true)
    }

    @Test func testBillingInvoiceFormatting() async throws {
        let invoice = BillingInvoice(
            id: "inv-1",
            invoiceNumber: "INV-2026-001",
            workOrderId: "wo-1",
            clientFacilityId: "fac-1",
            clerkId: "clerk-1",
            totalBillableLaborHours: "5.50",
            hourlyLaborRateApplied: "75.00",
            subtotalLabor: "412.50",
            subtotalApprovedParts: "200.00",
            partsMarkupPercentApplied: "20.00",
            subtotalPartsWithMarkup: "240.00",
            fleetEquipmentFee: "50.00",
            taxPercent: "8.00",
            taxAmount: "56.20",
            grandTotal: "758.70",
            status: .draftEstimate,
            issueDate: nil,
            dueDate: nil
        )

        #expect(invoice.formattedGrandTotal == "$758.70")
        #expect(invoice.formattedLaborTotal == "$412.50")
        #expect(invoice.formattedPartsTotal == "$240.00")
    }


    @Test func testAPIEndpointURL() async throws {
        let endpoint = APIEndpoint.health
        let req = try endpoint.makeRequest()
        #expect(req.url?.absoluteString == "https://whirl-dispatch-backend-h6ub.vercel.app/api/health")
        #expect(req.httpMethod == "GET")
    }

    @Test func testShiftWidgetSnapshotHasAssignedDispatch() async throws {
        let assignedSnapshot = ShiftWidgetSnapshot(
            isClockedIn: false,
            isOnBreak: false,
            clockInDate: nil,
            totalBreakSeconds: 0,
            activeWorkOrderNumber: "WO-2026-001",
            activeWorkOrderTitle: "Chiller Overhaul",
            activeFacilityName: "Apex Data Centers",
            todayTotalHours: 2.5,
            lastUpdated: Date()
        )
        #expect(assignedSnapshot.hasAssignedDispatch == true)

        let standbySnapshot = ShiftWidgetSnapshot(
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
        #expect(standbySnapshot.hasAssignedDispatch == false)
    }
}
