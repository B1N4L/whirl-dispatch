//
//  BillingInvoice.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-07.
//

import Foundation

enum InvoiceStatus: String, Codable, CaseIterable {
    case draftEstimate = "DRAFT_ESTIMATE"
    case approvedBySupervisor = "APPROVED_BY_SUPERVISOR"
    case issuedToClient = "ISSUED_TO_CLIENT"
    case paid = "PAID"

   var label: String {
       switch self {
       case .draftEstimate: return "Draft Estimate"
       case .approvedBySupervisor: return "Supervisor Approved"
       case .issuedToClient: return "Issued to Client"
       case .paid: return "Paid"
       }
   }
}


struct BillingInvoice: Identifiable, Codable, Equatable {
    let id: String
    let invoiceNumber: String
    let workOrderId: String
    let clientFacilityId: String
    let clerkId: String
    let totalBillableLaborHours: String
    let hourlyLaborRateApplied: String
    let subtotalLabor: String
    let subtotalApprovedParts: String
    let partsMarkupPercentApplied: String
    let subtotalPartsWithMarkup: String
    let fleetEquipmentFee: String
    let taxPercent: String
    let taxAmount: String
    let grandTotal: String
    var status: InvoiceStatus
    let issueDate: String?
    let dueDate: String?


    // formatted currency helpers
    var formattedGrandTotal: String {
       if let val = Double(grandTotal) {
           return String(format: "$%.2f", val)
       }
       return "$\(grandTotal)"
    }

    var formattedLaborTotal: String {
        if let val = Double(subtotalLabor) {
            return String(format: "$%.2f", val)
        }
        return "$\(subtotalLabor)"
    }

    var formattedPartsTotal: String {
        if let val = Double(subtotalPartsWithMarkup) {
            return String(format: "$%.2f", val)
        }
        return "$\(subtotalPartsWithMarkup)"
    }
}


struct LaborBreakdownItem: Identifiable, Codable, Equatable {
    var id: String { technicianId }
    let technicianId: String
    let technicianName: String
    let role: String
    let hourlyRate: Double
    let billableHours: Double
    let subtotal: Double

    var formattedHourlyRate: String {
        String(format: "$%.2f/hr", hourlyRate)
    }

    var formattedHours: String {
        String(format: "%.1f hrs", billableHours)
    }

    var formattedSubtotal: String {
        String(format: "$%.2f", subtotal)
    }

    var roleLabel: String {
        role == "LEAD_TECHNICIAN" ? "Lead Technician" : "Field Technician"
    }
}

struct BillingCalculationResult: Codable, Equatable {
    let workOrderId: String
    let clientFacilityId: String
    let totalBillableLaborHours: Double
    let hourlyLaborRateApplied: Double
    let subtotalLabor: Double
    let laborBreakdown: [LaborBreakdownItem]?
    let subtotalApprovedParts: Double
    let partsMarkupPercentApplied: Double
    let subtotalPartsWithMarkup: Double
    let fleetEquipmentFee: Double
    let taxPercent: Double
    let taxAmount: Double
    let grandTotal: Double
    let invoiceNumber: String
    let dueDate: String?
}

struct EstimateResponse: Codable {
    let message: String?
    let invoice: BillingInvoice?
    let calculation: BillingCalculationResult?
}

struct EstimatePreviewResponse: Codable {
    let calculation: BillingCalculationResult
    let existingInvoice: BillingInvoice?
}
