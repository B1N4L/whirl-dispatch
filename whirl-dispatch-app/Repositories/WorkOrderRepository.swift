//
//  WorkOrderRepository.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-13.
//

import Foundation

final class WorkOrderRepository: @unchecked Sendable {
    static let shared = WorkOrderRepository()

    private let apiService: APIService
    private let offlineStorage: OfflineStorageService

    init(
        apiService: APIService = .shared,
        offlineStorage: OfflineStorageService = .shared
    ) {
        self.apiService = apiService
        self.offlineStorage = offlineStorage
    }


    // try remote fetch first, fallback to core data if plant room basement has no signal or offline mode is engaged
    func fetchWorkOrders() async -> (orders: [WorkOrder], isOffline: Bool, error: String?) {
      if OfflineModeManager.shared.isPlantRoomOffline {
          let cachedOrders = await offlineStorage.fetchCachedWorkOrders()
          return (cachedOrders, true, nil)
      }

      do {
          // decode envelope wrapper or direct array if returned
          let remoteOrders: [WorkOrder]
          if let wrapper: WorkOrdersResponse = try? await apiService.send(.getWorkOrders) {
              remoteOrders = wrapper.workOrders
          } else {
              remoteOrders = try await apiService.send(.getWorkOrders)
          }

          // cache in background for offline use later
          await offlineStorage.upsertWorkOrders(remoteOrders)

          return (remoteOrders, false, nil)
      } catch {
          // network failed, attempt local core data cache recovery
          let cachedOrders = await offlineStorage.fetchCachedWorkOrders()

          if !cachedOrders.isEmpty {
              return (cachedOrders, true, nil)
          }

          return ([], true, "Network unreachable and no offline cache available.")
      }
    }


    // get details for work order
    func fetchWorkOrderDetail(id: String) async -> (order: WorkOrder?, isOffline: Bool) {
        if OfflineModeManager.shared.isPlantRoomOffline {
            let cached = await offlineStorage.fetchCachedWorkOrder(id: id)
            return (cached, true)
        }

        do {
            let remote: WorkOrder
            if let wrapper: WorkOrderDetailResponse = try? await apiService.send(.getWorkOrderDetail(id: id)) {
                remote = wrapper.workOrder
            } else {
                remote = try await apiService.send(.getWorkOrderDetail(id: id))
            }
            await offlineStorage.upsertWorkOrders([remote])
            return (remote, false)
        } catch {
            let cached = await offlineStorage.fetchCachedWorkOrder(id: id)
            return (cached, true)
        }
    }


    // update status with optimistic offline fallback
    func updateStatus(id: String, status: WorkOrderStatus) async -> (success: Bool, isOffline: Bool) {
      if OfflineModeManager.shared.isPlantRoomOffline {
          await offlineStorage.updateWorkOrderStatus(id: id, status: status, isSyncPending: true)
          return (true, true)
      }

      do {
          if let _: WorkOrderStatusUpdateResponse = try? await apiService.send(.updateWorkOrderStatus(id: id, status: status.rawValue)) {
              await offlineStorage.updateWorkOrderStatus(id: id, status: status, isSyncPending: false)
              return (true, false)
          } else {
              let _: WorkOrder = try await apiService.send(.updateWorkOrderStatus(id: id, status: status.rawValue))
              await offlineStorage.updateWorkOrderStatus(id: id, status: status, isSyncPending: false)
              return (true, false)
          }
      } catch {
          // network down, save change locally and mark as pending sync
          await offlineStorage.updateWorkOrderStatus(id: id, status: status, isSyncPending: true)
          return (true, true)
      }
    }


    // sync any mutations made while disconnected
    func syncPendingMutations() async -> Int {
        let count = await offlineStorage.getPendingSyncCount()
        // in future steps, iterate pending items and re-push
        return count
    }
}
