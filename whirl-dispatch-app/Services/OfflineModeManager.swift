//
//  OfflineModeManager.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-19.
//

import Foundation
import Observation

@Observable
final class OfflineModeManager: @unchecked Sendable {
    static let shared = OfflineModeManager()

    var isPlantRoomOffline: Bool = false
    var pendingSyncCount: Int = 0
    var restrictionErrorMessage: String? = nil

    private init() {}


    // toggle offline mode with strict on-site workplace validation
    @discardableResult
    func setPlantRoomOffline(enabled: Bool, for order: WorkOrder?) -> Bool {
      if enabled {
          // strictly verify technician is at the workplace site
          guard let order = order, order.status == .onSiteActive else {
              restrictionErrorMessage = "Offline Mode Restricted: You cannot enable offline mode outside the workplace site. You must arrive and clock in on-site first."
              isPlantRoomOffline = false
              return false
          }

          restrictionErrorMessage = nil
          isPlantRoomOffline = true
          return true
      } else {
          // switching back online
          isPlantRoomOffline = false
          restrictionErrorMessage = nil
          Task {
              await syncPendingChanges()
          }
          return true
      }
    }


    // refresh pending count from core data
    func refreshPendingCount() async {
        let count = await OfflineStorageService.shared.getPendingSyncCount()
        DispatchQueue.main.async {
            self.pendingSyncCount = count
        }
    }


    // push queued mutations to live backend
    func syncPendingChanges() async {
      _ = await WorkOrderRepository.shared.syncPendingMutations()
      await refreshPendingCount()
    }
}
