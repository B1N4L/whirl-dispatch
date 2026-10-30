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


    // single active dispatch resolution
    var currentDispatch: WorkOrder? {
        if let active = assignedWorkOrders.first(where: {
            $0.status == .onSiteActive || $0.status == .unacknowledgedBreak || $0.status == .awaitingPartsApproval || $0.status == .enRoute
        }) {
            return active
        }
        return assignedWorkOrders.first(where: { $0.status == .dispatched })
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

    // tally metrics
    var totalClaimedAmount: Double {
        claims.reduce(0.0) { acc, claim in
            acc + (Double(claim.totalAmount) ?? 0.0)
        }
    }

    var totalApprovedAmount: Double {
        claims.filter { $0.approvalStatus == .approved }.reduce(0.0) { acc, claim in
            acc + (Double(claim.totalAmount) ?? 0.0)
        }
    }

    var pendingCount: Int {
        claims.filter { $0.approvalStatus == .pending }.count
    }

    var approvedCount: Int {
        claims.filter { $0.approvalStatus == .approved }.count
    }

    var rejectedCount: Int {
        claims.filter { $0.approvalStatus == .rejected }.count
    }

    var formattedTotalClaimed: String {
        AppCurrency.format(totalClaimedAmount)
    }

    var formattedTotalApproved: String {
        AppCurrency.format(totalApprovedAmount)
    }


    // load work orders and their associated claims
    func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        // 1. fetch dispatches and filter strictly to active dispatches
        let (orders, _, _) = await WorkOrderRepository.shared.fetchWorkOrders()
        let activeOrders = orders.filter {
            $0.status == .onSiteActive || $0.status == .unacknowledgedBreak || $0.status == .awaitingPartsApproval || $0.status == .enRoute || $0.status == .dispatched
        }
        self.assignedWorkOrders = activeOrders

        // 2. if no active dispatch assigned, clear claims and return
        guard let dispatch = currentDispatch else {
            self.claims = []
            isLoading = false
            return
        }

        // if plant room offline mode is on, keep existing offline list
        if offlineManager.isPlantRoomOffline {
            isLoading = false
            return
        }

        // 3. fetch claims for current active dispatch from backend
        do {
            let res: WorkOrderExpensesResponse = try await apiService.send(.getExpensesByWorkOrder(workOrderId: dispatch.id))
            self.claims = res.claims
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
