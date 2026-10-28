//
//  WorkOrdersViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-18.
//

import Foundation
import SwiftUI
import Observation

enum WorkOrderFilter: String, CaseIterable, Identifiable {
    case all = "All Dispatches"
    case emergency = "Emergency"
    case active = "Active On-Site"
    case completed = "Completed"

    var id: String { rawValue }
}


@Observable
@MainActor
final class WorkOrdersViewModel {
    var workOrders: [WorkOrder] = []
    var selectedFilter: WorkOrderFilter = .all
    var searchQuery: String = ""
    var isLoading: Bool = false
    var isOffline: Bool = false
    var errorMessage: String? = nil

    private let repository: WorkOrderRepository

    init(repository: WorkOrderRepository? = nil) {
        self.repository = repository ?? .shared
    }


    // current active or primary upcoming dispatch for this technician
    var currentDispatch: WorkOrder? {
        // 1. check for currently active on-site or en-route job
        if let active = workOrders.first(where: {
            $0.status == .onSiteActive || $0.status == .unacknowledgedBreak || $0.status == .awaitingPartsApproval || $0.status == .enRoute
        }) {
            return active
        }
        // 2. otherwise, first scheduled dispatched job
        return workOrders.first(where: { $0.status == .dispatched })
    }

    // upcoming dispatched jobs beyond the current one
    var upcomingDispatches: [WorkOrder] {
        guard let current = currentDispatch else { return [] }
        return workOrders.filter { order in
            order.id != current.id && order.status == .dispatched
        }
    }

    // completed work orders that the technician participated in
    var completedHistory: [WorkOrder] {
        workOrders.filter { $0.status == .completed || $0.status == .billed }
    }

    // whether a search query is active
    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // search results matching search query across all dispatches
    var searchResults: [WorkOrder] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        return workOrders.filter { order in
            order.workOrderNumber.lowercased().contains(query) ||
            order.title.lowercased().contains(query) ||
            order.description.lowercased().contains(query) ||
            (order.facility?.facilityName.lowercased().contains(query) ?? false) ||
            (order.facility?.companyName.lowercased().contains(query) ?? false)
        }
    }


    // computed filtered list matching chips and search box
    var filteredWorkOrders: [WorkOrder] {
      var list = workOrders

      // filter by status tab
      switch selectedFilter {
      case .all:
          break
      case .emergency:
          list = list.filter { $0.priority == .criticalEmergency }
      case .active:
          list = list.filter { $0.status == .onSiteActive || $0.status == .enRoute }
      case .completed:
          list = list.filter { $0.status == .completed || $0.status == .billed }
      }

      // filter by search query if typed
      let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      if !query.isEmpty {
          list = list.filter { order in
              order.workOrderNumber.lowercased().contains(query) ||
              order.title.lowercased().contains(query) ||
              order.description.lowercased().contains(query) ||
              (order.facility?.facilityName.lowercased().contains(query) ?? false) ||
              (order.facility?.companyName.lowercased().contains(query) ?? false)
          }
      }

      return list
    }


    // load dispatches from repository with offline fallback
    func loadWorkOrders() async {
        isLoading = true
        errorMessage = nil

        let result = await repository.fetchWorkOrders()
        self.workOrders = result.orders
        self.isOffline = result.isOffline
        self.errorMessage = result.error
        self.isLoading = false
    }


    // update status for work order
    func transitionStatus(order: WorkOrder, to newStatus: WorkOrderStatus) async -> Bool {
      let (success, offline) = await repository.updateStatus(id: order.id, status: newStatus)
      if success {
          if let idx = workOrders.firstIndex(where: { $0.id == order.id }) {
              workOrders[idx].status = newStatus
          }
          self.isOffline = offline
          return true
      }
      return false
    }


    // helper count for chips
    func count(for filter: WorkOrderFilter) -> Int {
        switch filter {
        case .all:
            return workOrders.count
        case .emergency:
            return workOrders.filter { $0.priority == .criticalEmergency }.count
        case .active:
            return workOrders.filter { $0.status == .onSiteActive || $0.status == .enRoute }.count
        case .completed:
            return workOrders.filter { $0.status == .completed || $0.status == .billed }.count
        }
    }
}
