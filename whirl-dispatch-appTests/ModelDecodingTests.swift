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

    @Test func testMessageResponseDecoding() throws {
        let json = """
        {
            "message": "Password changed successfully"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(MessageResponse.self, from: json)
        #expect(response.message == "Password changed successfully")
    }

    @Test func testProfileSectionEnumeration() {
        let sections = ProfileSection.allCases
        #expect(sections.count == 4)
        #expect(ProfileSection.personalContact.iconName == "person.text.rectangle.fill")
        #expect(ProfileSection.securityPassword.iconName == "lock.shield.fill")
        #expect(ProfileSection.operationalRole.iconName == "briefcase.fill")
        #expect(ProfileSection.sessionDevice.iconName == "server.rack")
    }

    @Test func testTeamSiteTelemetryDecoding() throws {
        let json = """
        {
            "workOrderId": "wo-test-01",
            "workOrderNumber": "WO-2026-8812",
            "title": "HVAC Chiller Overhaul",
            "status": "ON_SITE_ACTIVE",
            "priority": "HIGH",
            "facility": {
                "id": "fac-01",
                "companyName": "Hemas Manufacturing",
                "facilityName": "Peliyagoda Plant",
                "address": "Peliyagoda Industrial Park",
                "latitude": 6.9602,
                "longitude": 79.8892,
                "geofenceRadius": 150.0,
                "contactPersonName": "Sunil Dias",
                "contactPhone": "+94771234567"
            },
            "team": [
                {
                    "id": "usr-lead-01",
                    "fullName": "Kasun Perera",
                    "email": "kasun.lead@whirldispatch.com",
                    "phone": "+94712345678",
                    "role": "LEAD_TECHNICIAN",
                    "isLead": true,
                    "isClockedIn": true,
                    "sessionStatus": "ACTIVE_ON_SITE",
                    "clockInTimestamp": "2026-10-28T02:00:00Z",
                    "latitude": 6.9603,
                    "longitude": 79.8893,
                    "isInsideGeofence": true,
                    "distanceToFacilityMeters": 18.5,
                    "formattedDistance": "19m"
                },
                {
                    "id": "usr-tech-01",
                    "fullName": "Nuwan Silva",
                    "email": "nuwan.tech@whirldispatch.com",
                    "phone": "+94763456789",
                    "role": "TECHNICIAN",
                    "isLead": false,
                    "isClockedIn": false,
                    "sessionStatus": "EN_ROUTE",
                    "clockInTimestamp": null,
                    "latitude": 6.9450,
                    "longitude": 79.8700,
                    "isInsideGeofence": false,
                    "distanceToFacilityMeters": 1850.0,
                    "formattedDistance": "1.9km"
                }
            ],
            "totalCrewCount": 2,
            "clockedInCount": 1,
            "insideGeofenceCount": 1
        }
        """.data(using: .utf8)!

        let telemetry = try JSONDecoder().decode(TeamSiteTelemetryResponse.self, from: json)
        #expect(telemetry.workOrderId == "wo-test-01")
        #expect(telemetry.workOrderNumber == "WO-2026-8812")
        #expect(telemetry.team.count == 2)
        #expect(telemetry.team[0].isLead == true)
        #expect(telemetry.team[0].initials == "KP")
        #expect(telemetry.team[0].isInsideGeofence == true)
        #expect(telemetry.team[1].isLead == false)
        #expect(telemetry.team[1].initials == "NS")
        #expect(telemetry.team[1].isInsideGeofence == false)
        #expect(telemetry.insideGeofenceCount == 1)
        #expect(telemetry.facility.geofenceRadius == 150.0)
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


    @Test func testTechniciansResponseDecodingAndAvailability() throws {
        let json = """
        {
            "count": 2,
            "technicians": [
                {
                    "id": "7e6582a2-65e8-4f73-a4d3-c43471317a27",
                    "fullName": "Kasun Lead",
                    "email": "lead@whirldispatch.com",
                    "phone": "+94 77 000 0000",
                    "role": "LEAD_TECHNICIAN",
                    "isAvailable": true,
                    "status": "Available",
                    "activeWorkOrderId": null,
                    "activeWorkOrderNumber": null,
                    "activeWorkOrderTitle": null,
                    "facilityName": null
                },
                {
                    "id": "ecf2e9d8-a387-49a0-bc40-2b909d1abe0f",
                    "fullName": "Dinesh Fernando",
                    "email": "dinesh.tech@whirldispatch.com",
                    "phone": "+94 75 456 7890",
                    "role": "TECHNICIAN",
                    "isAvailable": false,
                    "status": "Active On-Site",
                    "activeWorkOrderId": "wo-123",
                    "activeWorkOrderNumber": "WO-2026-0002",
                    "activeWorkOrderTitle": "Condenser Overhaul",
                    "facilityName": "WTC West Tower"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TechniciansResponse.self, from: json)
        #expect(response.count == 2)
        #expect(response.technicians.count == 2)

        let lead = response.technicians[0]
        #expect(lead.fullName == "Kasun Lead")
        #expect(lead.role == .leadTechnician)
        #expect(lead.isAvailable == true)
        #expect(lead.status == "Available")

        let crew = response.technicians[1]
        #expect(crew.fullName == "Dinesh Fernando")
        #expect(crew.role == .technician)
        #expect(crew.isAvailable == false)
        #expect(crew.status == "Active On-Site")
        #expect(crew.facilityName == "WTC West Tower")
    }


    @Test func testWorkOrderCreateResponseDecoding() throws {
        let json = """
        {
            "message": "Work order created and dispatched successfully.",
            "workOrder": {
                "id": "bcb63fc7-2f6c-4abb-8f26-6a4139d6a5c8",
                "workOrderNumber": "WO-2026-4845",
                "clientFacilityId": "47676ffe-3c6e-400f-961b-f37e864c949b",
                "supervisorId": "0b579731-de81-43b8-8284-c65bbc6db69f",
                "leadTechnicianId": "7e6582a2-65e8-4f73-a4d3-c43471317a27",
                "assignedFleetAssetId": "3fa5ff0c-0413-4ec2-84a7-d9d6272bb493",
                "title": "Chiller Compressor Bearing Emergency Inspection",
                "description": "Urgent vibration alarm triggered on chiller primary compressor shaft.",
                "priority": "HIGH",
                "status": "DISPATCHED",
                "scheduledStartTime": "2026-10-27T14:00:00.000Z",
                "scheduledEndTime": "2026-10-27T18:00:00.000Z",
                "actualStartTime": null,
                "actualEndTime": null
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WorkOrderCreateResponse.self, from: json)
        #expect(response.message == "Work order created and dispatched successfully.")
        #expect(response.workOrder.workOrderNumber == "WO-2026-4845")
        #expect(response.workOrder.priority == .high)
        #expect(response.workOrder.status == .dispatched)
    }


    @Test func testFleetListResponseDecoding() throws {
        let json = """
        {
            "count": 2,
            "fleet": [
                {
                    "id": "3fa5ff0c-0413-4ec2-84a7-d9d6272bb493",
                    "assetCode": "VAN-04",
                    "name": "Toyota HiAce Field Service Van #04",
                    "assetType": "VAN",
                    "licensePlate": "WP-CAA-4404",
                    "status": "AVAILABLE"
                },
                {
                    "id": "d17f1336-8ca2-4acb-b867-02013894eac3",
                    "assetCode": "CRANE-02",
                    "name": "Tadano 15-Ton Mobile Crane Truck #02",
                    "assetType": "CRANE_TRUCK",
                    "licensePlate": "WP-DA-8902",
                    "status": "DEPLOYED"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(FleetListResponse.self, from: json)
        #expect(response.count == 2)
        #expect(response.fleet.count == 2)
        #expect(response.fleet[0].assetCode == "VAN-04")
        #expect(response.fleet[0].status == .available)
        #expect(response.fleet[1].status == .deployed)
    }


    @Test func testNumericPriceResilienceInExpenseItemAndClaim() throws {
        let json = """
        {
            "id": "cd0d58d9-0d64-4edd-b499-530a497d4ffd",
            "workOrderId": "bcb63fc7-2f6c-4abb-8f26-6a4139d6a5c8",
            "leadTechnicianId": "7e6582a2-65e8-4f73-a4d3-c43471317a27",
            "vendorName": "Refrigeration Supplies Ltd",
            "receiptNumber": "INV-8899",
            "totalAmount": 90.5,
            "currency": "USD",
            "approvalStatus": "PENDING_SUPERVISOR_APPROVAL",
            "items": [
                {
                    "id": "10711201-c1fa-4d04-ba5b-bf262ef382a6",
                    "expenseClaimId": "cd0d58d9-0d64-4edd-b499-530a497d4ffd",
                    "partDescription": "High Pressure Gauge Hose",
                    "quantity": 2,
                    "unitPrice": 45,
                    "totalPrice": 90
                }
            ]
        }
        """.data(using: .utf8)!

        let claim = try JSONDecoder().decode(ExpenseClaim.self, from: json)
        #expect(claim.id == "cd0d58d9-0d64-4edd-b499-530a497d4ffd")
        #expect(claim.totalAmount == "90.50")
        #expect(claim.approvalStatus == .pending)

        let firstItem = try #require(claim.items?.first)
        #expect(firstItem.unitPrice == "45.00")
        #expect(firstItem.totalPrice == "90.00")
    }


    @Test func testExpenseListResponseDualKeyDecoding() throws {
        let json = """
        {
            "count": 1,
            "expenses": [
                {
                    "id": "exp-dual-01",
                    "workOrderId": "wo-123",
                    "leadTechnicianId": "tech-123",
                    "vendorName": "Apex Supply",
                    "totalAmount": "150.00",
                    "approvalStatus": "PENDING_SUPERVISOR_APPROVAL"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ExpenseListResponse.self, from: json)
        #expect(response.count == 1)
        #expect(response.expenses.count == 1)
        #expect(response.expenses[0].vendorName == "Apex Supply")
    }


    @Test func testCurrentAttendanceResponseDecoding() throws {
        let activeJson = """
        {
            "active": true,
            "session": {
                "id": "att-current-01",
                "workOrderId": "wo-991",
                "technicianId": "tech-01",
                "clockInTimestamp": "2026-10-27T08:00:00.000Z",
                "clockOutTimestamp": null,
                "totalBillableSeconds": 7200,
                "totalBreakSeconds": 600,
                "sessionStatus": "ACTIVE_ON_SITE"
            }
        }
        """.data(using: .utf8)!

        let activeRes = try JSONDecoder().decode(CurrentAttendanceResponse.self, from: activeJson)
        #expect(activeRes.active == true)
        #expect(activeRes.session?.id == "att-current-01")
        #expect(activeRes.session?.clockOutTimestamp == nil)
        #expect(activeRes.session?.sessionStatus == .activeOnSite)

        let inactiveJson = """
        {
            "active": false,
            "session": null
        }
        """.data(using: .utf8)!

        let inactiveRes = try JSONDecoder().decode(CurrentAttendanceResponse.self, from: inactiveJson)
        #expect(inactiveRes.active == false)
        #expect(inactiveRes.session == nil)
    }


    @Test func testFleetTrackingResponseDecodingAndTelemetry() throws {
        let json = """
        {
            "count": 1,
            "trackedSites": [
                {
                    "workOrderId": "wo-test-99",
                    "workOrderNumber": "WO-2026-9911",
                    "title": "Chiller Compressor Trip",
                    "description": "Oil pressure failure on loop B",
                    "status": "ON_SITE_ACTIVE",
                    "priority": "CRITICAL_EMERGENCY",
                    "scheduledStartTime": "2026-10-27T08:00:00Z",
                    "scheduledEndTime": "2026-10-27T12:00:00Z",
                    "facility": {
                        "id": "fac-01",
                        "companyName": "Metro Group",
                        "facilityName": "Metro HQ",
                        "address": "452 Galle Road",
                        "latitude": 6.9271,
                        "longitude": 79.8612,
                        "geofenceRadius": 150.0,
                        "contactPersonName": "Rohan",
                        "contactPhone": "+94112345678",
                        "slaResponseHours": 2
                    },
                    "team": {
                        "leadTechnician": {
                            "id": "usr-lead-01",
                            "fullName": "Kasun Fernando",
                            "email": "kasun@whirl.com",
                            "phone": "+94778899001",
                            "role": "LEAD_TECHNICIAN"
                        },
                        "crew": [
                            {
                                "id": "usr-tech-02",
                                "fullName": "Nimal Silva",
                                "email": "nimal@whirl.com",
                                "phone": "+94778899002",
                                "role": "TECHNICIAN"
                            }
                        ],
                        "totalHeadcount": 2
                    },
                    "vehicle": {
                        "id": "flt-01",
                        "assetCode": "VAN-01",
                        "name": "HiAce Van",
                        "assetType": "VAN",
                        "licensePlate": "WP-CAB-1234",
                        "status": "DEPLOYED"
                    },
                    "telemetry": {
                        "latitude": 6.92715,
                        "longitude": 79.86125,
                        "isInsideGeofence": true,
                        "distanceToFacilityMeters": 15.0,
                        "formattedDistance": "15m",
                        "lastPingTimestamp": "2026-10-27T09:30:00Z"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(FleetTrackingResponse.self, from: json)
        #expect(response.count == 1)
        #expect(response.trackedSites.count == 1)

        let site = response.trackedSites[0]
        #expect(site.workOrderId == "wo-test-99")
        #expect(site.isEmergency == true)
        #expect(site.isOnSite == true)
        #expect(site.isEnRoute == false)
        #expect(site.facility.latitude == 6.9271)
        #expect(site.team.leadTechnician?.initials == "KF")
        #expect(site.team.totalHeadcount == 2)
        #expect(site.vehicle?.licensePlate == "WP-CAB-1234")
        #expect(site.telemetry.isInsideGeofence == true)
        #expect(site.telemetry.formattedDistance == "15m")
    }


    @Test func testShiftWidgetSnapshotEncodingAndDecoding() throws {
        let now = Date()
        let clockIn = Calendar.current.date(byAdding: .hour, value: -3, to: now)

        let snapshot = ShiftWidgetSnapshot(
            isClockedIn: true,
            isOnBreak: false,
            clockInDate: clockIn,
            totalBreakSeconds: 1245,
            activeWorkOrderNumber: "WO-2026-9042",
            activeWorkOrderTitle: "Air Handling Unit Filter Replacement",
            activeFacilityName: "World Trade Center Colombo",
            todayTotalHours: 4.8,
            lastUpdated: now
        )

        #expect(snapshot.isClockedIn == true)
        #expect(snapshot.isOnBreak == false)
        #expect(snapshot.formattedBreakTime == "20m 45s")
        #expect(snapshot.formattedTodayHours == "4.8 hrs")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ShiftWidgetSnapshot.self, from: data)

        #expect(decoded.isClockedIn == true)
        #expect(decoded.isOnBreak == false)
        #expect(decoded.activeWorkOrderNumber == "WO-2026-9042")
        #expect(decoded.activeFacilityName == "World Trade Center Colombo")
        #expect(decoded.totalBreakSeconds == 1245)
        #expect(decoded.todayTotalHours == 4.8)
    }
}
