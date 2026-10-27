//
//  OfflineStorageService.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-13.
//

import Foundation
import CoreData

final class OfflineStorageService: @unchecked Sendable {
    static let shared = OfflineStorageService()

    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }


    // create isolated background context for writes
    private func createBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }


    // background context upsert to avoid blocking main thread
    func upsertWorkOrders(_ orders: [WorkOrder]) async {
      let context = createBackgroundContext()

      await context.perform {
          for order in orders {
              let fetchRequest: NSFetchRequest<CachedWorkOrder> = NSFetchRequest(entityName: "CachedWorkOrder")
              fetchRequest.predicate = NSPredicate(format: "id == %@", order.id)

              do {
                  let results = try context.fetch(fetchRequest)
                  let cached: CachedWorkOrder
                  if let existing = results.first {
                      cached = existing
                  } else {
                      cached = CachedWorkOrder(context: context)
                  }

                  cached.update(from: order)
              } catch {
                  // ignore single record error and continue loop
              }
          }

          if context.hasChanges {
              do {
                  try context.save()
              } catch {
                  // failed saving background context
              }
          }
      }
    }


    // fetch all cached work orders sorted by scheduled time
    func fetchCachedWorkOrders() async -> [WorkOrder] {
        let context = createBackgroundContext()

        return await context.perform {
            let fetchRequest: NSFetchRequest<CachedWorkOrder> = NSFetchRequest(entityName: "CachedWorkOrder")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "scheduledStartTime", ascending: true)]

            do {
                let records = try context.fetch(fetchRequest)
                return records.map { $0.toDomain() }
            } catch {
                return []
            }
        }
    }


    // fetch single work order by id
    func fetchCachedWorkOrder(id: String) async -> WorkOrder? {
        let context = createBackgroundContext()

        return await context.perform {
            let fetchRequest: NSFetchRequest<CachedWorkOrder> = NSFetchRequest(entityName: "CachedWorkOrder")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1

            do {
                let record = try context.fetch(fetchRequest).first
                return record?.toDomain()
            } catch {
                return nil
            }
        }
    }


    // update status for work order in local db
    func updateWorkOrderStatus(id: String, status: WorkOrderStatus, isSyncPending: Bool = true) async {
      let context = createBackgroundContext()

      await context.perform {
          let fetchRequest: NSFetchRequest<CachedWorkOrder> = NSFetchRequest(entityName: "CachedWorkOrder")
          fetchRequest.predicate = NSPredicate(format: "id == %@", id)

          if let cached = try? context.fetch(fetchRequest).first {
              cached.status = status.rawValue
              cached.isSyncPending = isSyncPending
              cached.lastUpdated = Date()

              try? context.save()
          }
      }
    }


    // upsert attendance record locally
    func upsertAttendance(_ record: AttendanceRecord, isSyncPending: Bool = false) async {
        let context = createBackgroundContext()

        await context.perform {
            let fetchRequest: NSFetchRequest<CachedAttendance> = NSFetchRequest(entityName: "CachedAttendance")
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.id)

            let cached: CachedAttendance
            if let existing = try? context.fetch(fetchRequest).first {
                cached = existing
            } else {
                cached = CachedAttendance(context: context)
            }

            cached.update(from: record)
            cached.isSyncPending = isSyncPending

            try? context.save()
        }
    }


    // fetch cached attendance record by work order id, prioritizing active unclosed sessions
    func fetchCachedAttendance(workOrderId: String) async -> AttendanceRecord? {
        let context = createBackgroundContext()

        return await context.perform {
            // 1. check for active unclosed shift first
            let activeReq: NSFetchRequest<CachedAttendance> = NSFetchRequest(entityName: "CachedAttendance")
            activeReq.predicate = NSPredicate(format: "workOrderId == %@ AND clockOutTimestamp == nil", workOrderId)
            activeReq.fetchLimit = 1

            if let active = try? context.fetch(activeReq).first {
                return active.toDomain()
            }

            // 2. fallback to latest historical session
            let fallbackReq: NSFetchRequest<CachedAttendance> = NSFetchRequest(entityName: "CachedAttendance")
            fallbackReq.predicate = NSPredicate(format: "workOrderId == %@", workOrderId)
            fallbackReq.sortDescriptors = [NSSortDescriptor(key: "clockInTimestamp", ascending: false)]
            fallbackReq.fetchLimit = 1

            if let latest = try? context.fetch(fallbackReq).first {
                return latest.toDomain()
            }
            return nil
        }
    }

    // fetch any currently active unclosed attendance session across all work orders
    func fetchActiveCachedAttendance() async -> AttendanceRecord? {
        let context = createBackgroundContext()

        return await context.perform {
            let activeReq: NSFetchRequest<CachedAttendance> = NSFetchRequest(entityName: "CachedAttendance")
            activeReq.predicate = NSPredicate(format: "clockOutTimestamp == nil")
            activeReq.sortDescriptors = [NSSortDescriptor(key: "clockInTimestamp", ascending: false)]
            activeReq.fetchLimit = 1

            if let active = try? context.fetch(activeReq).first {
                return active.toDomain()
            }
            return nil
        }
    }


    // check how many mutations are waiting for network sync
    func getPendingSyncCount() async -> Int {
      let context = createBackgroundContext()

      return await context.perform {
          let woReq: NSFetchRequest<CachedWorkOrder> = NSFetchRequest(entityName: "CachedWorkOrder")
          woReq.predicate = NSPredicate(format: "isSyncPending == YES")

          let attReq: NSFetchRequest<CachedAttendance> = NSFetchRequest(entityName: "CachedAttendance")
          attReq.predicate = NSPredicate(format: "isSyncPending == YES")

          let woCount = (try? context.count(for: woReq)) ?? 0
          let attCount = (try? context.count(for: attReq)) ?? 0

          return woCount + attCount
      }
    }
}
