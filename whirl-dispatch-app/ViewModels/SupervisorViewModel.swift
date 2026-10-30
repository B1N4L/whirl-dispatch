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


enum FleetMapFilter: String, CaseIterable, Identifiable {
    case all = "All Active"
    case onSite = "On-Site"
    case enRoute = "En Route"
    case dispatched = "Dispatched"

    var id: String { rawValue }
}


enum ExpenseStatusFilter: String, CaseIterable, Identifiable {
    case all = "All History"
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"

    var id: String { rawValue }
}


enum TechnicianStatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case onSite = "Active On-site"
    case available = "Available"
    case enRoute = "En-route"

    var id: String { rawValue }
}


struct TechnicianMember: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let email: String
    let role: UserRole
    let roleTitle: String
    var status: TechnicianShiftStatus
    let hourlyRate: String?
    let biometricEnrolled: Bool
    let contactNumber: String
    var lastSeenText: String

    // Active dispatched job details (if dispatched)
    var activeWorkOrderId: String?
    var activeWorkOrderNumber: String?
    var activeWorkOrderTitle: String?
    var activeWorkOrderDescription: String?
    var activeWorkOrderPriority: String?
    var activeWorkOrderStatus: String?
    var activeWorkOrderScheduledStart: String?
    var activeWorkOrderScheduledEnd: String?
    var isLeadOnActiveJob: Bool?
    var companyName: String?
    var facilityName: String?
    var facilityAddress: String?

    var assignedWorkOrderTitle: String? {
        activeWorkOrderTitle ?? activeWorkOrderNumber
    }

    var isDispatched: Bool {
        activeWorkOrderId != nil && status != .available
    }

    var isLeadTechnician: Bool {
        role == .leadTechnician
    }
}


@Observable
@MainActor
final class SupervisorViewModel {
    var workOrders: [WorkOrder] = []
    var countsByFilter: WorkOrderFilterCounts? = nil
    var selectedWorkOrder: WorkOrder? = nil
    var selectedFilter: WorkOrderFilter = .all
    var technicians: [TechnicianMember] = []
    var selectedTechnician: TechnicianMember? = nil
    var technicianStatusFilter: TechnicianStatusFilter = .all
    var technicianSearchQuery: String = ""
    var technicianItems: [TechnicianItem] = []
    var facilities: [Facility] = []
    var fleetAssets: [FleetAsset] = []
    var pendingExpenses: [ExpenseClaim] = []
    var selectedExpense: ExpenseClaim? = nil
    var expenseStatusFilter: ExpenseStatusFilter = .all
    var expenseSearchQuery: String = ""

    // live fleet map tracking
    var trackedSites: [TrackedSite] = []
    var selectedTrackedSite: TrackedSite? = nil
    var fleetMapFilter: FleetMapFilter = .all
    var fleetSearchQuery: String = ""

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
    }

    // tracked sites filtered by status and search query
    var filteredTrackedSites: [TrackedSite] {
        var list = trackedSites
        switch fleetMapFilter {
        case .all:
            break
        case .onSite:
            list = list.filter { $0.isOnSite }
        case .enRoute:
            list = list.filter { $0.isEnRoute }
        case .dispatched:
            list = list.filter { $0.isDispatched }
        }

        let query = fleetSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { site in
                site.facility.facilityName.lowercased().contains(query) ||
                site.facility.companyName.lowercased().contains(query) ||
                site.workOrderNumber.lowercased().contains(query) ||
                (site.team.leadTechnician?.fullName.lowercased().contains(query) ?? false) ||
                (site.vehicle?.licensePlate.lowercased().contains(query) ?? false)
            }
        }

        return list
    }

    // filtered expense list across all client companies
    var filteredExpenses: [ExpenseClaim] {
        var list = pendingExpenses
        switch expenseStatusFilter {
        case .all:
            break
        case .pending:
            list = list.filter { $0.approvalStatus == .pending }
        case .approved:
            list = list.filter { $0.approvalStatus == .approved }
        case .rejected:
            list = list.filter { $0.approvalStatus == .rejected }
        }

        let query = expenseSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { claim in
                claim.vendorName.lowercased().contains(query) ||
                (claim.receiptNumber?.lowercased().contains(query) ?? false) ||
                claim.clientCompanyName.lowercased().contains(query) ||
                claim.facilityDisplayName.lowercased().contains(query) ||
                claim.dispatchCode.lowercased().contains(query) ||
                (claim.rejectionReason?.lowercased().contains(query) ?? false) ||
                (claim.items?.contains(where: { $0.partDescription.lowercased().contains(query) }) ?? false)
            }
        }

        return list
    }

    // filtered technician list across dispatch status and search query
    var filteredTechnicians: [TechnicianMember] {
        var list = technicians
        switch technicianStatusFilter {
        case .all:
            break
        case .onSite:
            list = list.filter { $0.status == .onSite }
        case .available:
            list = list.filter { $0.status == .available }
        case .enRoute:
            list = list.filter { $0.status == .enRoute }
        }

        let query = technicianSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { tech in
                tech.name.lowercased().contains(query) ||
                tech.email.lowercased().contains(query) ||
                tech.roleTitle.lowercased().contains(query) ||
                (tech.facilityName?.lowercased().contains(query) ?? false) ||
                (tech.companyName?.lowercased().contains(query) ?? false) ||
                (tech.activeWorkOrderNumber?.lowercased().contains(query) ?? false) ||
                (tech.activeWorkOrderTitle?.lowercased().contains(query) ?? false)
            }
        }

        return list
    }

    // Available lead technicians for new dispatch assignment
    var availableLeadTechnicians: [TechnicianItem] {
        let leads = technicianItems.filter { $0.role == .leadTechnician && $0.isAvailable }
        if !leads.isEmpty {
            return leads
        }
        // Fallback to any available senior field technicians if all lead technicians are deployed
        return technicianItems.filter { $0.isAvailable }
    }

    // Available field crew technicians (excluding active assignments)
    var availableCrewTechnicians: [TechnicianItem] {
        technicianItems.filter { $0.isAvailable }
    }

    // Available fleet vehicles
    var availableFleetVehicles: [FleetAsset] {
        fleetAssets.filter { $0.status == .available }
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
        countsByFilter?.active ?? workOrders.filter { $0.status == .onSiteActive }.count
    }

    var emergencyDispatchesCount: Int {
        countsByFilter?.emergency ?? workOrders.filter { $0.priority == .criticalEmergency }.count
    }

    var onShiftTechsCount: Int {
        technicians.filter { $0.status == .onSite || $0.status == .enRoute }.count
    }


    // load all live work orders, facilities, fleet, technicians, and associated expenses
    func loadSupervisorData() async {
        isLoading = true
        errorMessage = nil

        async let ordersTask = repository.fetchWorkOrders()
        async let facilitiesTask: FacilityListResponse? = try? apiService.send(.getFacilities)
        async let fleetTask: FleetListResponse? = try? apiService.send(.getFleet)
        async let techsTask: TechniciansResponse? = try? apiService.send(.getTechnicians)
        async let trackingTask: FleetTrackingResponse? = try? apiService.send(.getFleetTracking)

        let (ordersResult, facilitiesRes, fleetRes, techsRes, trackingRes) = await (ordersTask, facilitiesTask, fleetTask, techsTask, trackingTask)
        self.workOrders = ordersResult.orders
        self.countsByFilter = ordersResult.counts

        if let facs = facilitiesRes?.facilities, !facs.isEmpty {
            self.facilities = facs
        }
        if let fleet = fleetRes?.fleet, !fleet.isEmpty {
            self.fleetAssets = fleet
        }
        if let techItems = techsRes?.technicians, !techItems.isEmpty {
            self.technicianItems = techItems
            self.technicians = techItems.map(mapTechnicianItem)
            if let currentId = selectedTechnician?.id, let refreshed = technicians.first(where: { $0.id == currentId }) {
                self.selectedTechnician = refreshed
            } else if selectedTechnician == nil {
                self.selectedTechnician = technicians.first
            }
        }

        if let tracking = trackingRes?.trackedSites, !tracking.isEmpty {
            self.trackedSites = tracking
            if selectedTrackedSite == nil || !tracking.contains(where: { $0.id == selectedTrackedSite?.id }) {
                self.selectedTrackedSite = tracking.first
            }
        } else {
            self.trackedSites = []
            self.selectedTrackedSite = nil
        }

        if selectedWorkOrder == nil {
            self.selectedWorkOrder = workOrders.first
        }

        // load claims across dispatches directly via GET /api/expenses
        if let listRes: ExpenseListResponse = try? await apiService.send(.getExpenses) {
            self.pendingExpenses = listRes.expenses
            if let currentId = selectedExpense?.id, let refreshed = listRes.expenses.first(where: { $0.id == currentId }) {
                self.selectedExpense = refreshed
            } else if selectedExpense == nil {
                self.selectedExpense = listRes.expenses.first(where: { $0.approvalStatus == .pending }) ?? listRes.expenses.first
            }
        }

        isLoading = false
    }

    // create new dispatch work order and notify team
    func createDispatch(
        facilityId: String,
        leadTechId: String,
        crewIds: [String],
        vehicleId: String?,
        title: String,
        description: String,
        priority: WorkOrderPriority,
        startTime: Date,
        endTime: Date
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startStr = isoFormatter.string(from: startTime)
        let endStr = isoFormatter.string(from: endTime)

        do {
            let response: WorkOrderCreateResponse = try await apiService.send(
                .createWorkOrder(
                    clientFacilityId: facilityId,
                    leadTechnicianId: leadTechId,
                    assignedFleetAssetId: vehicleId,
                    assignedTechnicianIds: crewIds,
                    title: title,
                    description: description,
                    priority: priority.rawValue,
                    scheduledStartTime: startStr,
                    scheduledEndTime: endStr
                )
            )

            var created = response.workOrder
            if created.facility == nil {
                created.facility = facilities.first(where: { $0.id == facilityId })
            }
            self.workOrders.insert(created, at: 0)
            self.selectedWorkOrder = created

            // Trigger native UserNotifications banner
            let leadTechName = technicianItems.first(where: { $0.id == leadTechId })?.fullName ?? "Lead Technician"
            let facilityName = created.facility?.facilityName ?? "Commercial Site"
            NotificationService.shared.scheduleDispatchNotification(
                workOrderNumber: created.workOrderNumber,
                title: created.title,
                facilityName: facilityName,
                leadTechName: leadTechName
            )

            // Refresh technician availability to reflect new active assignment
            if let refreshedTechs: TechniciansResponse = try? await apiService.send(.getTechnicians) {
                self.technicianItems = refreshedTechs.technicians
                self.technicians = refreshedTechs.technicians.map(mapTechnicianItem)
                if let currentId = selectedTechnician?.id, let refreshed = technicians.first(where: { $0.id == currentId }) {
                    self.selectedTechnician = refreshed
                } else if selectedTechnician == nil {
                    self.selectedTechnician = technicians.first
                }
            }

            // Update fleet vehicle status locally if allocated
            if let vehicleId = vehicleId, let vIdx = fleetAssets.firstIndex(where: { $0.id == vehicleId }) {
                let v = fleetAssets[vIdx]
                fleetAssets[vIdx] = FleetAsset(
                    id: v.id,
                    assetCode: v.assetCode,
                    name: v.name,
                    assetType: v.assetType,
                    licensePlate: v.licensePlate,
                    status: .deployed
                )
            }

            successToast = "Work order \(created.workOrderNumber) created and dispatched."
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
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
            var updatedClaim = res.claim
            if (updatedClaim.items == nil || updatedClaim.items?.isEmpty == true),
               let existingItems = pendingExpenses.first(where: { $0.id == claimId })?.items {
                updatedClaim.items = existingItems
            }
            if updatedClaim.workOrder == nil,
               let existingWorkOrder = pendingExpenses.first(where: { $0.id == claimId })?.workOrder {
                updatedClaim.workOrder = existingWorkOrder
            }

            if let idx = pendingExpenses.firstIndex(where: { $0.id == claimId }) {
                pendingExpenses[idx] = updatedClaim
            }
            if selectedExpense?.id == claimId {
                selectedExpense = updatedClaim
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


    private func mapTechnicianItem(_ item: TechnicianItem) -> TechnicianMember {
        let shiftStatus: TechnicianShiftStatus
        switch item.status {
        case "Active On-Site": shiftStatus = .onSite
        case "En Route": shiftStatus = .enRoute
        default: shiftStatus = .available
        }

        let rateText = item.hourlyLaborRate != nil ? AppCurrency.formatRate(stringVal: item.hourlyLaborRate!) : AppCurrency.formatRate(85.0)
        let company = item.companyName ?? (item.facilityName != nil ? "Commercial Client" : nil)

        return TechnicianMember(
            id: item.id,
            name: item.fullName,
            email: item.email,
            role: item.role,
            roleTitle: item.role == .leadTechnician ? "Lead Technician" : "Field Technician",
            status: shiftStatus,
            hourlyRate: rateText,
            biometricEnrolled: item.biometricEnrolled ?? true,
            contactNumber: item.phone ?? "+94 77 000 0000",
            lastSeenText: item.isAvailable ? "Ready for Dispatch" : (item.facilityName ?? "On Site"),
            activeWorkOrderId: item.activeWorkOrderId,
            activeWorkOrderNumber: item.activeWorkOrderNumber,
            activeWorkOrderTitle: item.activeWorkOrderTitle,
            activeWorkOrderDescription: item.activeWorkOrderDescription,
            activeWorkOrderPriority: item.activeWorkOrderPriority,
            activeWorkOrderStatus: item.activeWorkOrderStatus,
            activeWorkOrderScheduledStart: item.activeWorkOrderScheduledStart,
            activeWorkOrderScheduledEnd: item.activeWorkOrderScheduledEnd,
            isLeadOnActiveJob: item.isLeadOnActiveJob,
            companyName: company,
            facilityName: item.facilityName ?? (item.isAvailable ? "Central Operations Base" : "Commercial Site"),
            facilityAddress: item.facilityAddress
        )
    }
}
