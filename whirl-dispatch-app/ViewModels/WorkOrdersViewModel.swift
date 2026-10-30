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
    var countsByFilter: WorkOrderFilterCounts? = nil
    var selectedFilter: WorkOrderFilter = .all
    var isLoading: Bool = false
    var isOffline: Bool = false
    var errorMessage: String? = nil

    private let repository: WorkOrderRepository

    init(repository: WorkOrderRepository? = nil) {
        self.repository = repository ?? .shared
    }


    // current active dispatch for this technician (single active dispatch model)
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

    // completed work orders that the technician participated in
    var completedHistory: [WorkOrder] {
        workOrders.filter { $0.status == .completed || $0.status == .billed }
    }

    // total history pages for completed dispatch history pagination
    func totalHistoryPages(pageSize: Int = 5) -> Int {
        max(1, Int(ceil(Double(completedHistory.count) / Double(pageSize))))
    }

    // slice of completed work orders for the given 1-based page index
    func paginatedHistory(page: Int, pageSize: Int = 5) -> [WorkOrder] {
        let startIndex = (page - 1) * pageSize
        guard startIndex < completedHistory.count else { return [] }
        let endIndex = min(startIndex + pageSize, completedHistory.count)
        return Array(completedHistory[startIndex..<endIndex])
    }


    // computed filtered list matching chips
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

      return list
    }


    // load dispatches from repository with offline fallback
    func loadWorkOrders() async {
        isLoading = true
        errorMessage = nil

        let result = await repository.fetchWorkOrders()
        self.workOrders = result.orders
        self.countsByFilter = result.counts
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
            return countsByFilter?.all ?? workOrders.count
        case .emergency:
            return countsByFilter?.emergency ?? workOrders.filter { $0.priority == .criticalEmergency }.count
        case .active:
            return countsByFilter?.active ?? workOrders.filter { $0.status == .onSiteActive || $0.status == .enRoute }.count
        case .completed:
            return countsByFilter?.completed ?? workOrders.filter { $0.status == .completed || $0.status == .billed }.count
        }
    }
}
