//
//  ModelDecodingTests.swift
//  whirl-dispatch-appTests
//
//  Created by Binal on 2026-10-26.
//

import Testing
import Foundation
import CoreLocation
@testable import whirl_dispatch_app

@MainActor
struct ModelDecodingTests {

    @Test func testUserDecodingAndComputedProperties() throws {
        let json = """
        {
            "id": "usr-test-99",
            "email": "kasun.fernando@whirldispatch.com",
            "fullName": "Kasun Fernando",
            "phone": "+94778899001",
            "role": "LEAD_TECHNICIAN",
            "hourlyLaborRate": "65.50",
            "biometricEnrolled": true,
            "isActive": true,
            "createdAt": "2026-10-06T08:30:00Z"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)

        #expect(user.id == "usr-test-99")
        #expect(user.email == "kasun.fernando@whirldispatch.com")
        #expect(user.fullName == "Kasun Fernando")
        #expect(user.role == .leadTechnician)
        #expect(user.role.displayName == "Lead Technician")
        #expect(user.initials == "KF")
        #expect(user.biometricEnrolled == true)
        #expect(user.isActive == true)
    }


    @Test func testFacilityJSONDecodingAndCoordinateConversion() throws {
        let json = """
        {
            "id": "fac-col-10",
            "companyName": "Cargills Food City PLC",
            "facilityName": "Staple Street Central Hub",
            "address": "40 York St, Colombo 00100",
            "latitude": 6.9344,
            "longitude": 79.8428,
            "geofenceRadius": 150.0,
            "contactPersonName": "Rohan Jayasuriya",
            "contactPhone": "+94112345678",
            "contactEmail": "facilities@cargills.lk",
            "slaResponseHours": 2,
            "contractHourlyRate": "85.00",
            "partsMarkupPercent": "18.50"
        }
        """.data(using: .utf8)!

        let facility = try JSONDecoder().decode(Facility.self, from: json)

        #expect(facility.id == "fac-col-10")
        #expect(facility.facilityName == "Staple Street Central Hub")
        #expect(facility.latitude == 6.9344)
        #expect(facility.longitude == 79.8428)
        #expect(facility.geofenceRadius == 150.0)
        #expect(facility.slaResponseHours == 2)
        #expect(facility.coordinate.latitude == 6.9344)
        #expect(facility.coordinate.longitude == 79.8428)
        #expect(facility.displayName == "Cargills Food City PLC - Staple Street Central Hub")
    }


    @Test func testWorkOrderDecodingAndEmergencyClockInRules() throws {
        let json = """
        {
            "id": "wo-test-404",
            "workOrderNumber": "WO-2026-8821",
            "clientFacilityId": "fac-col-10",
            "supervisorId": "sup-lead-01",
            "leadTechnicianId": "tech-lead-02",
            "assignedFleetAssetId": "VAN-CHIL-04",
            "title": "Chiller Secondary Loop Failure",
            "description": "Suction pressure dropped below safety trip boundary.",
            "priority": "CRITICAL_EMERGENCY",
            "status": "DISPATCHED",
            "scheduledStartTime": "2026-10-26T10:00:00Z",
            "scheduledEndTime": "2026-10-26T14:00:00Z",
            "actualStartTime": null,
            "actualEndTime": null
        }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(WorkOrder.self, from: json)

        #expect(order.workOrderNumber == "WO-2026-8821")
        #expect(order.priority == .criticalEmergency)
        #expect(order.isEmergency == true)
        #expect(order.canClockIn == true)
        #expect(order.status == .dispatched)
        #expect(order.assignedFleetAssetId == "VAN-CHIL-04")
    }


    @Test func testDiagnosticDossierDecodingWithChecklistItems() throws {
        let json = """
        {
            "id": "dos-77",
            "workOrderId": "wo-test-404",
            "leadTechnicianId": "tech-lead-02",
            "equipmentModel": "Carrier AquaSnap 30MP",
            "equipmentSerialNumber": "SN-2024-CHIL-8849",
            "baselineSuctionPressurePsi": "68.5",
            "postServiceSuctionPressurePsi": "72.0",
            "baselineDischargePressurePsi": "245.0",
            "postServiceDischargePressurePsi": "220.0",
            "baselineMotorRunningAmps": "18.2",
            "postServiceMotorRunningAmps": "15.4",
            "technicianNotes": "Coil micro-channels straightened, refrigerant topped up.",
            "supervisorReviewNotes": null,
            "isWorkApproved": true,
            "checklist": [
                {
                    "id": "chk-01",
                    "category": "COMPRESSOR_SYSTEM",
                    "itemLabel": "Inspect compressor oil sight glass",
                    "isChecked": true,
                    "notes": "Clear, 3/4 level"
                },
                {
                    "id": "chk-04",
                    "category": "REFRIGERANT_CIRCUIT",
                    "itemLabel": "Halogen leak detector scan on schrader valves",
                    "isChecked": true,
                    "notes": null
                }
            ],
            "photos": [
                {
                    "id": "pho-01",
                    "diagnosticDossierId": "dos-77",
                    "photoType": "BASELINE_BEFORE",
                    "photoUrl": "https://storage.whirldispatch.com/proof-01.jpg",
                    "capturedTimestamp": "2026-10-26T10:15:00Z",
                    "latitude": 6.9344,
                    "longitude": 79.8428
                }
            ]
        }
        """.data(using: .utf8)!

        let dossier = try JSONDecoder().decode(DiagnosticDossier.self, from: json)

        #expect(dossier.id == "dos-77")
        #expect(dossier.equipmentModel == "Carrier AquaSnap 30MP")
        #expect(dossier.baselineSuctionPressurePsi == "68.5")
        #expect(dossier.postServiceSuctionPressurePsi == "72.0")
        #expect(dossier.isWorkApproved == true)
        #expect(dossier.checklist?.count == 2)
        #expect(dossier.checklist?.first?.category == .compressor)
        #expect(dossier.photos?.count == 1)
        #expect(dossier.photos?.first?.photoType == .baselineBefore)
    }


    @Test func testExpenseClaimDecodingAndApprovalStatus() throws {
        let json = """
        {
            "id": "exp-501",
            "workOrderId": "wo-test-404",
            "leadTechnicianId": "tech-lead-02",
            "vendorName": "United Refrigeration Supply",
            "receiptNumber": "REC-9912",
            "totalAmount": "245.50",
            "approvalStatus": "APPROVED",
            "supervisorNotes": "Pre-authorized emergency contactor replacement.",
            "submittedAt": "2026-10-26T11:30:00Z",
            "reviewedAt": "2026-10-26T12:00:00Z",
            "items": [
                {
                    "id": "item-01",
                    "expenseClaimId": "exp-501",
                    "partDescription": "Square-D 3-Pole 40A Contactor",
                    "quantity": 1,
                    "unitPrice": "180.00",
                    "totalPrice": "180.00"
                },
                {
                    "id": "item-02",
                    "expenseClaimId": "exp-501",
                    "partDescription": "Neoprene vibration isolator pad",
                    "quantity": 4,
                    "unitPrice": "16.375",
                    "totalPrice": "65.50"
                }
            ]
        }
        """.data(using: .utf8)!

        let claim = try JSONDecoder().decode(ExpenseClaim.self, from: json)

        #expect(claim.id == "exp-501")
        #expect(claim.vendorName == "United Refrigeration Supply")
        #expect(claim.supplierName == "United Refrigeration Supply")
        #expect(claim.totalAmount == "245.50")
        #expect(claim.approvalStatus == .approved)
        #expect(claim.approvalStatus.label == "Approved")
        #expect(claim.items?.count == 2)
        #expect(claim.items?.first?.partDescription == "Square-D 3-Pole 40A Contactor")
        #expect(claim.formattedAmount == "$245.50")
    }


    @Test func testBillingInvoiceFormulasAndCurrencyFormatting() throws {
        let json = """
        {
            "id": "inv-901",
            "invoiceNumber": "INV-2026-0901",
            "workOrderId": "wo-test-404",
            "clientFacilityId": "fac-col-10",
            "clerkId": "clerk-binal",
            "totalBillableLaborHours": "4.50",
            "hourlyLaborRateApplied": "85.00",
            "subtotalLabor": "382.50",
            "subtotalApprovedParts": "245.50",
            "partsMarkupPercentApplied": "20.00",
            "subtotalPartsWithMarkup": "294.60",
            "fleetEquipmentFee": "45.00",
            "taxPercent": "8.00",
            "taxAmount": "57.77",
            "grandTotal": "779.87",
            "status": "ISSUED_TO_CLIENT",
            "issueDate": "2026-10-26T15:00:00Z",
            "dueDate": "2026-11-26T15:00:00Z"
        }
        """.data(using: .utf8)!

        let invoice = try JSONDecoder().decode(BillingInvoice.self, from: json)

        #expect(invoice.invoiceNumber == "INV-2026-0901")
        #expect(invoice.status == .issuedToClient)
        #expect(invoice.formattedGrandTotal == "$779.87")
        #expect(invoice.formattedLaborTotal == "$382.50")
        #expect(invoice.formattedPartsTotal == "$294.60")
    }


    @Test func testNeonDBEnvelopeAndNumericRateDecoding() throws {
        let envelopeJson = """
        {
            "count": 1,
            "workOrders": [
                {
                    "id": "392a4c30-a41d-431e-b2a9-b5acdea53753",
                    "workOrderNumber": "WO-2026-8173",
                    "clientFacilityId": "0eb3bf55-916f-4c59-8fe1-5963076fc6da",
                    "supervisorId": "0b579731-de81-43b8-8284-c65bbc6db69f",
                    "leadTechnicianId": "d33fe7a4-28ca-4e4d-bcad-655ef8418447",
                    "assignedFleetAssetId": "d17f1336-8ca2-4acb-b867-02013894eac3",
                    "title": "Commercial HVAC Quarterly Invoicing Audit",
                    "description": "Scheduled preventive overhaul.",
                    "priority": "HIGH",
                    "status": "BILLED",
                    "scheduledStartTime": "2026-10-25T19:01:50.255Z",
                    "scheduledEndTime": "2026-10-26T00:01:50.255Z",
                    "actualStartTime": "2026-10-25T19:01:52.891Z",
                    "actualEndTime": null,
                    "facility": {
                        "id": "0eb3bf55-916f-4c59-8fe1-5963076fc6da",
                        "companyName": "Dialog Axiata PLC",
                        "facilityName": "Dialog Headquarters Data Center AHU",
                        "address": "475 Union Place, Colombo 02",
                        "latitude": 6.918,
                        "longitude": 79.862,
                        "geofenceRadius": 100.0,
                        "contactPersonName": "Sunil Perera",
                        "contactPhone": "+94 11 710 0100",
                        "contactEmail": "sunil.p@dialog.lk",
                        "slaResponseHours": 2,
                        "contractHourlyRate": 95,
                        "partsMarkupPercent": 18
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WorkOrdersResponse.self, from: envelopeJson)
        #expect(response.count == 1)
        #expect(response.workOrders.count == 1)

        let firstOrder = response.workOrders[0]
        #expect(firstOrder.workOrderNumber == "WO-2026-8173")
        #expect(firstOrder.facility?.contractHourlyRate == "95.00")
        #expect(firstOrder.facility?.partsMarkupPercent == "18.00")
        #expect(firstOrder.facility?.companyName == "Dialog Axiata PLC")
    }
}
