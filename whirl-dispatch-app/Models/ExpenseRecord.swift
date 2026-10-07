//
//  ExpenseRecord.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-07.
//

import Foundation

enum ExpenseApprovalStatus: String, Codable, CaseIterable {
    case pending = "PENDING_SUPERVISOR_APPROVAL"
    case approved = "APPROVED"
    case rejected = "REJECTED"

   var label: String {
       switch self {
       case .pending: return "Pending Review"
       case .approved: return "Approved"
       case .rejected: return "Rejected"
       }
   }

    var badgeColorName: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
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
    let supplierName: String
   let invoiceNumber: String
    let totalAmount: String
    let receiptStoreLatitude: Double
    let receiptStoreLongitude: Double
    let receiptCapturedAt: String?
    var approvalStatus: ExpenseApprovalStatus
   var reviewedBySupervisorId: String?
    var reviewedAt: String?
    var rejectionReason: String?
   var items: [ExpenseItem]?

    // display formatted amount
    var formattedAmount: String {
       if let val = Double(totalAmount) {
           return String(format: "$%.2f", val)
       }
       return "$\(totalAmount)"
    }
}
