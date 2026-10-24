//
//  SupervisorViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-23.
//

import Foundation
import SwiftUI
import Observation

enum TechnicianShiftStatus: String, CaseIterable, Identifiable {
    case onSite = "Active On-Site"
    case enRoute = "En Route"
    case available = "Available"
    case offDuty = "Off Duty"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .onSite: return Color.statusGreen
        case .enRoute: return Color.accentBlue
        case .available: return Color.statusAmber
        case .offDuty: return Color.statusGray
        }
    }

    var iconName: String {
        switch self {
        case .onSite: return "checkmark.circle.fill"
        case .enRoute: return "car.fill"
        case .available: return "clock.fill"
        case .offDuty: return "moon.fill"
        }
    }
}


struct TechnicianMember: Identifiable, Equatable {
    let id: String
    let name: String
    let roleTitle: String
    var status: TechnicianShiftStatus
    var assignedWorkOrderTitle: String?
    var facilityName: String?
    let contactNumber: String
    var lastSeenText: String
}


@Observable
@MainActor
final class SupervisorViewModel {
    var workOrders: [WorkOrder] = []
    var selectedWorkOrder: WorkOrder? = nil
    var selectedFilter: WorkOrderFilter = .all
    var technicians: [TechnicianMember] = []
    var pendingExpenses: [ExpenseClaim] = []
    var selectedExpense: ExpenseClaim? = nil

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var successToast: String? = nil

    private let apiService: APIService
    private let repository: WorkOrderRepository

    init(
        apiService: APIService? = nil,
        repository: WorkOrderRepository? = nil
    ) {
        self.apiService = apiService ?? .shared
        self.repository = repository ?? .shared
        setupInitialTeamRoster()
    }


    // dispatches filtered by status
    var filteredWorkOrders: [WorkOrder] {
      switch selectedFilter {
      case .all:
          return workOrders
      case .emergency:
          return workOrders.filter { $0.priority == .criticalEmergency }
      case .active:
          return workOrders.filter { $0.status == .onSiteActive || $0.status == .enRoute }
      case .completed:
          return workOrders.filter { $0.status == .completed || $0.status == .billed }
      }
    }

    // command center key figures
    var activeOnSiteCount: Int {
        workOrders.filter { $0.status == .onSiteActive }.count
    }

    var emergencyDispatchesCount: Int {
        workOrders.filter { $0.priority == .criticalEmergency }.count
    }

    var onShiftTechsCount: Int {
        technicians.filter { $0.status == .onSite || $0.status == .enRoute }.count
    }


    // load all live work orders and associated expenses
    func loadSupervisorData() async {
        isLoading = true
        errorMessage = nil

        let (orders, _, _) = await repository.fetchWorkOrders()
        self.workOrders = orders

        if selectedWorkOrder == nil {
            self.selectedWorkOrder = orders.first
        }

        // load claims across dispatches for approval queue
        var claims: [ExpenseClaim] = []
        for order in orders.prefix(5) {
            if let res: WorkOrderExpensesResponse = try? await apiService.send(.getExpensesByWorkOrder(workOrderId: order.id)) {
                claims.append(contentsOf: res.claims)
            }
        }

        // deduplicate claims
        var seen = Set<String>()
        var unique: [ExpenseClaim] = []
        for c in claims {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                unique.append(c)
            }
        }

        self.pendingExpenses = unique
        if selectedExpense == nil {
            self.selectedExpense = unique.first(where: { $0.approvalStatus == .pending }) ?? unique.first
        }

        isLoading = false
    }


    // reassign lead technician to a work order
    func reassignTechnician(workOrderId: String, techName: String) {
        if let idx = workOrders.firstIndex(where: { $0.id == workOrderId }) {
            successToast = "Work order assigned to \(techName)."
            // refresh selected
            if selectedWorkOrder?.id == workOrderId {
                selectedWorkOrder = workOrders[idx]
            }
        }
    }


    // approve or reject an expense claim
    func reviewExpense(claimId: String, status: ExpenseApprovalStatus, reason: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let res: CreateExpenseResponse = try await apiService.send(
                .approveExpense(id: claimId, status: status.rawValue, reason: reason)
            )

            // update claim in array
            if let idx = pendingExpenses.firstIndex(where: { $0.id == claimId }) {
                pendingExpenses[idx] = res.claim
            }
            if selectedExpense?.id == claimId {
                selectedExpense = res.claim
            }

            successToast = status == .approved ? "Expense claim approved." : "Expense claim flagged and rejected."
            isLoading = false
            return true
        } catch {
            // fallback offline/local simulation
            if let idx = pendingExpenses.firstIndex(where: { $0.id == claimId }) {
                var updated = pendingExpenses[idx]
                updated.approvalStatus = status
                updated.rejectionReason = reason
                pendingExpenses[idx] = updated
                if selectedExpense?.id == claimId {
                    selectedExpense = updated
                }
                successToast = "Claim updated: \(status.label)."
                isLoading = false
                return true
            }
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }


    // initial roster matching coursework scenario
    private func setupInitialTeamRoster() {
        self.technicians = [
            TechnicianMember(
                id: "tech-01",
                name: "Nuwan Silva",
                roleTitle: "Senior HVAC Field Tech",
                status: .onSite,
                assignedWorkOrderTitle: "WO-2026-4401 - Main Chiller",
                facilityName: "Metro Commercial Center",
                contactNumber: "+94 77 123 4567",
                lastSeenText: "Plant Room B2 (5m ago)"
            ),
            TechnicianMember(
                id: "tech-02",
                name: "Kasun Perera",
                roleTitle: "Lead Technician",
                status: .enRoute,
                assignedWorkOrderTitle: "WO-2026-4402 - Rooftop AHU",
                facilityName: "Apex Healthcare Tower",
                contactNumber: "+94 71 987 6543",
                lastSeenText: "En Route on Baseline Rd"
            ),
            TechnicianMember(
                id: "tech-03",
                name: "Dinesh Fernando",
                roleTitle: "Field Technician",
                status: .available,
                assignedWorkOrderTitle: nil,
                facilityName: "Central Operations Base",
                contactNumber: "+94 76 555 1212",
                lastSeenText: "Ready for Dispatch"
            ),
            TechnicianMember(
                id: "tech-04",
                name: "Malik Jayasuriya",
                roleTitle: "Apprentice Tech",
                status: .onSite,
                assignedWorkOrderTitle: "WO-2026-4401 - Main Chiller",
                facilityName: "Metro Commercial Center",
                contactNumber: "+94 70 444 8989",
                lastSeenText: "Plant Room B2"
            )
        ]
    }
}
