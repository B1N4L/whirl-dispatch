//
//  ExpensesViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-23.
//

import Foundation
import SwiftUI
import Observation

enum ExpenseFilter: String, CaseIterable, Identifiable {
    case all = "All Claims"
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"

    var id: String { rawValue }
}


@Observable
@MainActor
final class ExpensesViewModel {
    var claims: [ExpenseClaim] = []
    var assignedWorkOrders: [WorkOrder] = []
    var selectedFilter: ExpenseFilter = .all
    var financialSummary: ExpenseFinancialSummary? = nil

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var successMessage: String? = nil
    var showNewExpenseSheet: Bool = false

    private let apiService: APIService
    private let offlineManager: OfflineModeManager

    init(
        apiService: APIService? = nil,
        offlineManager: OfflineModeManager? = nil
    ) {
        self.apiService = apiService ?? .shared
        self.offlineManager = offlineManager ?? .shared
    }


    // single active dispatch resolution directly backed by backend
    var currentDispatch: WorkOrder? {
        assignedWorkOrders.first
    }

    // filtered list for current selection
    var filteredClaims: [ExpenseClaim] {
      switch selectedFilter {
      case .all:
          return claims
      case .pending:
          return claims.filter { $0.approvalStatus == .pending }
      case .approved:
          return claims.filter { $0.approvalStatus == .approved }
      case .rejected:
          return claims.filter { $0.approvalStatus == .rejected }
      }
    }

    // tally metrics leveraging server summary with offline fallback
    var totalClaimedAmount: Double {
        if let summary = financialSummary {
            return summary.totalClaimedAmount
        }
        return claims.reduce(0.0) { acc, claim in
            acc + (Double(claim.totalAmount) ?? 0.0)
        }
    }

    var totalApprovedAmount: Double {
        if let summary = financialSummary {
            return summary.totalApprovedAmount
        }
        return claims.filter { $0.approvalStatus == .approved }.reduce(0.0) { acc, claim in
            acc + (Double(claim.totalAmount) ?? 0.0)
        }
    }

    var pendingCount: Int {
        financialSummary?.pendingClaimsCount ?? claims.filter { $0.approvalStatus == .pending }.count
    }

    var approvedCount: Int {
        financialSummary?.approvedClaimsCount ?? claims.filter { $0.approvalStatus == .approved }.count
    }

    var rejectedCount: Int {
        financialSummary?.rejectedClaimsCount ?? claims.filter { $0.approvalStatus == .rejected }.count
    }

    var formattedTotalClaimed: String {
        AppCurrency.format(totalClaimedAmount)
    }

    var formattedTotalApproved: String {
        AppCurrency.format(totalApprovedAmount)
    }


    // load active dispatch and its associated claims in a single server call
    func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        // if plant room offline mode is on, keep existing offline list
        if offlineManager.isPlantRoomOffline {
            isLoading = false
            return
        }

        do {
            let res: ActiveDispatchExpensesResponse = try await apiService.send(.getActiveExpenses)
            if res.hasActiveDispatch, let active = res.workOrder {
                self.assignedWorkOrders = [active]
                self.claims = res.claims
                self.financialSummary = res.financialSummary
            } else {
                self.assignedWorkOrders = []
                self.claims = []
                self.financialSummary = nil
            }
        } catch {
            if claims.isEmpty {
                self.errorMessage = "Unable to fetch online expense claims for active dispatch."
            }
        }

        isLoading = false
    }


    // submit emergency part expense claim
    func submitExpense(
        workOrderId: String,
        vendorName: String,
        receiptNumber: String?,
        unitPrice: Double,
        quantity: Int,
        partDescription: String,
        category: PartCategory
    ) async -> String? {
      let lineTotal = Double(quantity) * unitPrice
      let isThresholdExceeded = lineTotal > 250.0
      let fullPartDescription = "[\(category.rawValue)] \(partDescription)"

      // if plant room offline mode is active, queue claim locally
      if offlineManager.isPlantRoomOffline {
          let claimId = UUID().uuidString
          let localItem = ExpenseItem(
              id: UUID().uuidString,
              expenseClaimId: claimId,
              partDescription: fullPartDescription,
              quantity: quantity,
              unitPrice: String(format: "%.2f", unitPrice),
              totalPrice: String(format: "%.2f", lineTotal)
          )

          let localClaim = ExpenseClaim(
              id: claimId,
              workOrderId: workOrderId,
              leadTechnicianId: "local-user",
              vendorName: vendorName,
              receiptNumber: receiptNumber,
              totalAmount: String(format: "%.2f", lineTotal),
              currency: "LKR",
              receiptImageUrl: nil,
              receiptStoreLatitude: 6.9271,
              receiptStoreLongitude: 79.8612,
              receiptCapturedAt: ISO8601DateFormatter().string(from: Date()),
              isThresholdExceeded: isThresholdExceeded,
              approvalStatus: .pending,
              reviewedBySupervisorId: nil,
              reviewedAt: nil,
              rejectionReason: nil,
              items: [localItem]
          )

          claims.insert(localClaim, at: 0)
          successMessage = "Saved locally. Will sync when exiting Plant Room Mode."
          return nil
      }

      // online live submission
      do {
          let itemsPayload: [[String: Any]] = [
              [
                  "partDescription": fullPartDescription,
                  "quantity": quantity,
                  "unitPrice": unitPrice
              ]
          ]

          let endpoint = APIEndpoint.submitExpense(
              workOrderId: workOrderId,
              vendorName: vendorName,
              receiptNumber: receiptNumber,
              currency: "LKR",
              receiptImageUrl: nil,
              lat: 6.9271,
              lng: 79.8612,
              items: itemsPayload
          )

          let response: CreateExpenseResponse = try await apiService.send(endpoint)
          var created = response.claim
          if created.items == nil || created.items?.isEmpty == true {
              created.items = response.items
          }

          claims.insert(created, at: 0)
          successMessage = "Emergency parts claim submitted for supervisor approval."
          return nil
      } catch {
          // fallback save locally on network failure
          let errText = error.localizedDescription
          errorMessage = errText
          return errText
      }
    }
}
