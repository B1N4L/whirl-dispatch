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
    var selectedWorkOrderId: String = ""
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


    // filtered list for current selection
    var filteredClaims: [ExpenseClaim] {
      var list = claims

      if !selectedWorkOrderId.isEmpty {
          list = list.filter { $0.workOrderId == selectedWorkOrderId }
      }

      switch selectedFilter {
      case .all:
          return list
      case .pending:
          return list.filter { $0.approvalStatus == .pending }
      case .approved:
          return list.filter { $0.approvalStatus == .approved }
      case .rejected:
          return list.filter { $0.approvalStatus == .rejected }
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalClaimedAmount)) ?? String(format: "$%.2f", totalClaimedAmount)
    }

    var formattedTotalApproved: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalApprovedAmount)) ?? String(format: "$%.2f", totalApprovedAmount)
    }


    // load work orders and their associated claims
    func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        // 1. fetch dispatches
        let (orders, _, _) = await WorkOrderRepository.shared.fetchWorkOrders()
        self.assignedWorkOrders = orders

        // if no order selected yet, default to first or keep empty for all
        if selectedWorkOrderId.isEmpty, let first = orders.first {
            selectedWorkOrderId = first.id
        }

        // if plant room offline mode is on, keep existing offline list
        if offlineManager.isPlantRoomOffline {
            isLoading = false
            return
        }

        // 2. fetch claims from backend
        do {
            var fetchedClaims: [ExpenseClaim] = []

            if !selectedWorkOrderId.isEmpty {
                let res: WorkOrderExpensesResponse = try await apiService.send(.getExpensesByWorkOrder(workOrderId: selectedWorkOrderId))
                fetchedClaims = res.claims
            } else {
                // fetch all company expenses or query dispatches
                if let listRes: ExpenseListResponse = try? await apiService.send(.getExpenses) {
                    fetchedClaims = listRes.expenses
                } else {
                    for order in orders.prefix(6) {
                        if let res: WorkOrderExpensesResponse = try? await apiService.send(.getExpensesByWorkOrder(workOrderId: order.id)) {
                            fetchedClaims.append(contentsOf: res.claims)
                        }
                    }
                }
            }

            // deduplicate claims by id
            var seen = Set<String>()
            var unique: [ExpenseClaim] = []
            for claim in fetchedClaims {
                if !seen.contains(claim.id) {
                    seen.insert(claim.id)
                    unique.append(claim)
                }
            }

            self.claims = unique
        } catch {
            // retain existing local claims on failure
            if claims.isEmpty {
                self.errorMessage = "Unable to fetch online expense claims. Check server status."
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
    ) async -> Bool {
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
              currency: "USD",
              receiptImageUrl: "file://local/receipt_\(claimId).jpg",
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
          return true
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

          let placeholderImage = "https://whirldispatch.blob.core.windows.net/receipts/proof_\(UUID().uuidString.prefix(8)).jpg"
          let endpoint = APIEndpoint.submitExpense(
              workOrderId: workOrderId,
              vendorName: vendorName,
              receiptNumber: receiptNumber,
              currency: "USD",
              receiptImageUrl: placeholderImage,
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
          return true
      } catch {
          // fallback save locally on network failure
          errorMessage = error.localizedDescription
          return false
      }
    }
}
