//
//  ExpenseRecord.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-07.
//

import Foundation
import SwiftUI

enum ExpenseApprovalStatus: String, Codable, CaseIterable, Hashable {
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


struct ExpenseItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let expenseClaimId: String?
    let partDescription: String
    let quantity: Int
    let unitPrice: String
    let totalPrice: String

    var formattedUnitPrice: String {
        AppCurrency.format(stringVal: unitPrice)
    }

    var formattedTotalPrice: String {
        AppCurrency.format(stringVal: totalPrice)
    }

    enum CodingKeys: String, CodingKey {
        case id, expenseClaimId, partDescription, quantity, unitPrice, totalPrice
    }

    init(
        id: String,
        expenseClaimId: String? = nil,
        partDescription: String,
        quantity: Int,
        unitPrice: String,
        totalPrice: String
    ) {
        self.id = id
        self.expenseClaimId = expenseClaimId
        self.partDescription = partDescription
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        expenseClaimId = try container.decodeIfPresent(String.self, forKey: .expenseClaimId)
        partDescription = try container.decode(String.self, forKey: .partDescription)
        quantity = try container.decode(Int.self, forKey: .quantity)

        // Resiliently decode unitPrice whether backend sends numeric double/int or formatted string
        if let str = try? container.decode(String.self, forKey: .unitPrice) {
            unitPrice = str
        } else if let num = try? container.decode(Double.self, forKey: .unitPrice) {
            unitPrice = String(format: "%.2f", num)
        } else if let intVal = try? container.decode(Int.self, forKey: .unitPrice) {
            unitPrice = "\(intVal).00"
        } else {
            unitPrice = "0.00"
        }

        // Resiliently decode totalPrice whether backend sends numeric double/int or formatted string
        if let str = try? container.decode(String.self, forKey: .totalPrice) {
            totalPrice = str
        } else if let num = try? container.decode(Double.self, forKey: .totalPrice) {
            totalPrice = String(format: "%.2f", num)
        } else if let intVal = try? container.decode(Int.self, forKey: .totalPrice) {
            totalPrice = "\(intVal).00"
        } else {
            totalPrice = "0.00"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(expenseClaimId, forKey: .expenseClaimId)
        try container.encode(partDescription, forKey: .partDescription)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
        try container.encode(totalPrice, forKey: .totalPrice)
    }
}


struct ExpenseFacilitySummary: Codable, Equatable, Hashable {
    let id: String
    let companyName: String
    let facilityName: String
    let address: String?
}

struct ExpenseWorkOrderSummary: Codable, Equatable, Hashable {
    let id: String
    let workOrderNumber: String
    let title: String
    let facility: ExpenseFacilitySummary?
}

struct ExpenseClaim: Identifiable, Codable, Equatable, Hashable {
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
    var workOrder: ExpenseWorkOrderSummary?

    enum CodingKeys: String, CodingKey {
        case id, workOrderId, leadTechnicianId, vendorName, receiptNumber
        case totalAmount, currency, receiptImageUrl, receiptStoreLatitude
        case receiptStoreLongitude, receiptCapturedAt, isThresholdExceeded
        case approvalStatus, reviewedBySupervisorId, reviewedAt, rejectionReason, items
        case workOrder
    }

    init(
        id: String,
        workOrderId: String,
        leadTechnicianId: String,
        vendorName: String,
        receiptNumber: String? = nil,
        totalAmount: String,
        currency: String? = "USD",
        receiptImageUrl: String? = nil,
        receiptStoreLatitude: Double? = nil,
        receiptStoreLongitude: Double? = nil,
        receiptCapturedAt: String? = nil,
        isThresholdExceeded: Bool? = nil,
        approvalStatus: ExpenseApprovalStatus = .pending,
        reviewedBySupervisorId: String? = nil,
        reviewedAt: String? = nil,
        rejectionReason: String? = nil,
        items: [ExpenseItem]? = nil,
        workOrder: ExpenseWorkOrderSummary? = nil
    ) {
        self.id = id
        self.workOrderId = workOrderId
        self.leadTechnicianId = leadTechnicianId
        self.vendorName = vendorName
        self.receiptNumber = receiptNumber
        self.totalAmount = totalAmount
        self.currency = currency
        self.receiptImageUrl = receiptImageUrl
        self.receiptStoreLatitude = receiptStoreLatitude
        self.receiptStoreLongitude = receiptStoreLongitude
        self.receiptCapturedAt = receiptCapturedAt
        self.isThresholdExceeded = isThresholdExceeded
        self.approvalStatus = approvalStatus
        self.reviewedBySupervisorId = reviewedBySupervisorId
        self.reviewedAt = reviewedAt
        self.rejectionReason = rejectionReason
        self.items = items
        self.workOrder = workOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        workOrderId = try container.decode(String.self, forKey: .workOrderId)
        leadTechnicianId = try container.decode(String.self, forKey: .leadTechnicianId)
        vendorName = try container.decode(String.self, forKey: .vendorName)
        receiptNumber = try container.decodeIfPresent(String.self, forKey: .receiptNumber)

        // Resiliently decode totalAmount whether string or numeric
        if let str = try? container.decode(String.self, forKey: .totalAmount) {
            totalAmount = str
        } else if let num = try? container.decode(Double.self, forKey: .totalAmount) {
            totalAmount = String(format: "%.2f", num)
        } else if let intVal = try? container.decode(Int.self, forKey: .totalAmount) {
            totalAmount = "\(intVal).00"
        } else {
            totalAmount = "0.00"
        }

        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        receiptImageUrl = try container.decodeIfPresent(String.self, forKey: .receiptImageUrl)
        receiptStoreLatitude = try container.decodeIfPresent(Double.self, forKey: .receiptStoreLatitude)
        receiptStoreLongitude = try container.decodeIfPresent(Double.self, forKey: .receiptStoreLongitude)
        receiptCapturedAt = try container.decodeIfPresent(String.self, forKey: .receiptCapturedAt)
        isThresholdExceeded = try container.decodeIfPresent(Bool.self, forKey: .isThresholdExceeded)
        approvalStatus = try container.decode(ExpenseApprovalStatus.self, forKey: .approvalStatus)
        reviewedBySupervisorId = try container.decodeIfPresent(String.self, forKey: .reviewedBySupervisorId)
        reviewedAt = try container.decodeIfPresent(String.self, forKey: .reviewedAt)
        rejectionReason = try container.decodeIfPresent(String.self, forKey: .rejectionReason)
        items = try container.decodeIfPresent([ExpenseItem].self, forKey: .items)
        workOrder = try container.decodeIfPresent(ExpenseWorkOrderSummary.self, forKey: .workOrder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workOrderId, forKey: .workOrderId)
        try container.encode(leadTechnicianId, forKey: .leadTechnicianId)
        try container.encode(vendorName, forKey: .vendorName)
        try container.encodeIfPresent(receiptNumber, forKey: .receiptNumber)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encodeIfPresent(receiptImageUrl, forKey: .receiptImageUrl)
        try container.encodeIfPresent(receiptStoreLatitude, forKey: .receiptStoreLatitude)
        try container.encodeIfPresent(receiptStoreLongitude, forKey: .receiptStoreLongitude)
        try container.encodeIfPresent(receiptCapturedAt, forKey: .receiptCapturedAt)
        try container.encodeIfPresent(isThresholdExceeded, forKey: .isThresholdExceeded)
        try container.encode(approvalStatus, forKey: .approvalStatus)
        try container.encodeIfPresent(reviewedBySupervisorId, forKey: .reviewedBySupervisorId)
        try container.encodeIfPresent(reviewedAt, forKey: .reviewedAt)
        try container.encodeIfPresent(rejectionReason, forKey: .rejectionReason)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(workOrder, forKey: .workOrder)
    }

    var clientCompanyName: String {
        workOrder?.facility?.companyName ?? "Commercial Client"
    }

    var facilityDisplayName: String {
        workOrder?.facility?.facilityName ?? "Regional Facility"
    }

    var dispatchCode: String {
        workOrder?.workOrderNumber ?? "WO-\(workOrderId.prefix(8).uppercased())"
    }

    var supplierName: String {
        vendorName
    }

    var invoiceNumber: String {
        receiptNumber ?? "INV-PENDING"
    }

    // display formatted amount
    var formattedAmount: String {
        AppCurrency.format(stringVal: totalAmount)
    }
}


// response wrapper for submit expense
struct CreateExpenseResponse: Codable {
    let message: String?
    let claim: ExpenseClaim
    let items: [ExpenseItem]?
}

struct ExpenseListResponse: Codable {
    let count: Int?
    let expenses: [ExpenseClaim]

    enum CodingKeys: String, CodingKey {
        case count, expenses, claims
    }

    init(expenses: [ExpenseClaim], count: Int? = nil) {
        self.expenses = expenses
        self.count = count ?? expenses.count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decodeIfPresent(Int.self, forKey: .count)
        if let exp = try? container.decode([ExpenseClaim].self, forKey: .expenses) {
            expenses = exp
        } else if let clm = try? container.decode([ExpenseClaim].self, forKey: .claims) {
            expenses = clm
        } else {
            expenses = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(count, forKey: .count)
        try container.encode(expenses, forKey: .expenses)
    }
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
