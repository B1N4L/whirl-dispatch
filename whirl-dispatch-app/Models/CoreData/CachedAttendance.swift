//
//  CachedAttendance.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-12.
//

import Foundation
import CoreData

@objc(CachedAttendance)
public class CachedAttendance: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var workOrderId: String?
    @NSManaged public var technicianId: String?
    @NSManaged public var clockInTimestamp: String?
    @NSManaged public var clockOutTimestamp: String?
    @NSManaged public var totalBillableSeconds: Int32
    @NSManaged public var totalBreakSeconds: Int32
    @NSManaged public var sessionStatus: String?
    @NSManaged public var isSyncPending: Bool


    // convert to domain attendance record
    func toDomain() -> AttendanceRecord {
        let status = SessionStatus(rawValue: sessionStatus ?? "ACTIVE_ON_SITE") ?? .activeOnSite

        return AttendanceRecord(
            id: id,
            workOrderId: workOrderId ?? "",
            technicianId: technicianId ?? "",
            clockInTimestamp: clockInTimestamp ?? "",
            clockOutTimestamp: clockOutTimestamp,
            totalBillableSeconds: Int(totalBillableSeconds),
            totalBreakSeconds: Int(totalBreakSeconds),
            sessionStatus: status
        )
    }

    // copy properties from domain dto
    func update(from record: AttendanceRecord) {
      self.id = record.id
      self.workOrderId = record.workOrderId
      self.technicianId = record.technicianId
      self.clockInTimestamp = record.clockInTimestamp
      self.clockOutTimestamp = record.clockOutTimestamp
      self.totalBillableSeconds = Int32(record.totalBillableSeconds)
      self.totalBreakSeconds = Int32(record.totalBreakSeconds)
      self.sessionStatus = record.sessionStatus.rawValue
    }
}
