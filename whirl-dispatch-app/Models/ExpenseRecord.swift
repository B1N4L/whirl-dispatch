//
//  ExpenseRecord.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-07.
//

import Foundation
import SwiftUI

enum ExpenseApprovalStatus: String, Codable, CaseIterable {
    case pending = "PENDING_SUPERVISOR_APPROVAL"
    case approved = "APPROVED"
    case rejected = "FLAGGED_REJECTED"

    var label: String {
        switch self {
        case .pending: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }

    var color: Color {
        switch self {
        case .pending: return Color.statusAmber
        case .approved: return Color.statusGreen
        case .rejected: return Color.statusRed
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "hourglass"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        }
    }
}


enum PartCategory: String, CaseIterable, Identifiable {
    case refrigerant = "Refrigerant Gas"
    case compressor = "Compressor Parts"
    case electrical = "Electrical & Wiring"
    case filtersPiping = "Filters & Piping"
    case hardware = "General Hardware"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .refrigerant: return "wind"
        case .compressor: return "gearshape.2.fill"
        case .electrical: return "bolt.fill"
        case .filtersPiping: return "air.purifier.fill"
        case .hardware: return "wrench.fill"
        }
    }
}


struct ExpenseItem: Identifiable, Codable, Equatable {
    let id: String
    let expenseClaimId: String?
    let partDescription: String
    let quantity: Int
    let unitPrice: String
    let totalPrice: String
}


struct ExpenseClaim: Identifiable, Codable, Equatable {
    let id: String
    let workOrderId: String
    let leadTechnicianId: String
    let vendorName: String
    let receiptNumber: String?
    let totalAmount: String
    let currency: String?
    let receiptImageUrl: String?
    let receiptStoreLatitude: Double?
    let receiptStoreLongitude: Double?
    let receiptCapturedAt: String?
    var isThresholdExceeded: Bool?
    var approvalStatus: ExpenseApprovalStatus
    var reviewedBySupervisorId: String?
    var reviewedAt: String?
    var rejectionReason: String?
    var items: [ExpenseItem]?


    var supplierName: String {
        vendorName
    }

    var invoiceNumber: String {
        receiptNumber ?? "INV-PENDING"
    }

    // display formatted amount
    var formattedAmount: String {
      if let val = Double(totalAmount) {
          return String(format: "$%.2f", val)
      }
      return "$\(totalAmount)"
    }
}


// response wrapper for submit expense
struct CreateExpenseResponse: Codable {
    let message: String?
    let claim: ExpenseClaim
    let items: [ExpenseItem]?
}

struct ExpenseListResponse: Codable {
    let expenses: [ExpenseClaim]
}

struct ExpenseFinancialSummary: Codable, Equatable {
    let totalClaimedAmount: Double
    let totalApprovedAmount: Double
    let pendingClaimsCount: Int
    let approvedClaimsCount: Int
    let rejectedClaimsCount: Int
}

struct WorkOrderExpensesResponse: Codable {
    let workOrderId: String
    let claimsCount: Int
    let claims: [ExpenseClaim]
    let financialSummary: ExpenseFinancialSummary?
}
