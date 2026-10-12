//
//  CachedWorkOrder.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-12.
//

import Foundation
import CoreData

@objc(CachedWorkOrder)
public class CachedWorkOrder: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var workOrderNumber: String?
    @NSManaged public var clientFacilityId: String?
    @NSManaged public var supervisorId: String?
    @NSManaged public var leadTechnicianId: String?
    @NSManaged public var assignedFleetAssetId: String?
    @NSManaged public var title: String?
    @NSManaged public var orderDescription: String?
    @NSManaged public var priority: String?
    @NSManaged public var status: String?
    @NSManaged public var scheduledStartTime: String?
    @NSManaged public var scheduledEndTime: String?
    @NSManaged public var actualStartTime: String?
    @NSManaged public var actualEndTime: String?

    // cached snapshot of facility
    @NSManaged public var facilityCompanyName: String?
    @NSManaged public var facilityName: String?
    @NSManaged public var facilityAddress: String?
    @NSManaged public var facilityLatitude: Double
    @NSManaged public var facilityLongitude: Double
    @NSManaged public var facilityGeofenceRadius: Double
    @NSManaged public var facilityContactName: String?
    @NSManaged public var facilityContactPhone: String?
    @NSManaged public var facilityContactEmail: String?
    @NSManaged public var facilitySlaHours: Int32
    @NSManaged public var facilityHourlyRate: String?
    @NSManaged public var facilityPartsMarkup: String?

    @NSManaged public var isSyncPending: Bool
    @NSManaged public var lastUpdated: Date?


    // convert to domain work order dto
    func toDomain() -> WorkOrder {
        let workPriority = WorkOrderPriority(rawValue: priority ?? "MEDIUM") ?? .medium
        let workStatus = WorkOrderStatus(rawValue: status ?? "DISPATCHED") ?? .dispatched

        var facilityDto: Facility? = nil
        if let fComp = facilityCompanyName, let fName = facilityName {
            facilityDto = Facility(
                id: clientFacilityId ?? "FAC-001",
                companyName: fComp,
                facilityName: fName,
                address: facilityAddress ?? "Plant Room",
                latitude: facilityLatitude,
                longitude: facilityLongitude,
                geofenceRadius: facilityGeofenceRadius > 0 ? facilityGeofenceRadius : 150.0,
                contactPersonName: facilityContactName ?? "Site Manager",
                contactPhone: facilityContactPhone ?? "+1 (555) 000-0000",
                contactEmail: facilityContactEmail,
                slaResponseHours: Int(facilitySlaHours),
                contractHourlyRate: facilityHourlyRate,
                partsMarkupPercent: facilityPartsMarkup
            )
        }

        return WorkOrder(
            id: id,
            workOrderNumber: workOrderNumber ?? "WO-PENDING",
            clientFacilityId: clientFacilityId ?? "FAC-001",
            supervisorId: supervisorId ?? "SUP-001",
            leadTechnicianId: leadTechnicianId ?? "TECH-001",
            assignedFleetAssetId: assignedFleetAssetId,
            title: title ?? "HVAC Maintenance",
            description: orderDescription ?? "",
            priority: workPriority,
            status: workStatus,
            scheduledStartTime: scheduledStartTime ?? "",
            scheduledEndTime: scheduledEndTime ?? "",
            actualStartTime: actualStartTime,
            actualEndTime: actualEndTime,
            facility: facilityDto
        )
    }


    // update properties from domain dto
    func update(from order: WorkOrder) {
      self.id = order.id
      self.workOrderNumber = order.workOrderNumber
      self.clientFacilityId = order.clientFacilityId
      self.supervisorId = order.supervisorId
      self.leadTechnicianId = order.leadTechnicianId
      self.assignedFleetAssetId = order.assignedFleetAssetId
      self.title = order.title
      self.orderDescription = order.description
      self.priority = order.priority.rawValue
      self.status = order.status.rawValue
      self.scheduledStartTime = order.scheduledStartTime
      self.scheduledEndTime = order.scheduledEndTime
      self.actualStartTime = order.actualStartTime
      self.actualEndTime = order.actualEndTime

      if let fac = order.facility {
          self.facilityCompanyName = fac.companyName
          self.facilityName = fac.facilityName
          self.facilityAddress = fac.address
          self.facilityLatitude = fac.latitude
          self.facilityLongitude = fac.longitude
          self.facilityGeofenceRadius = fac.geofenceRadius
          self.facilityContactName = fac.contactPersonName
          self.facilityContactPhone = fac.contactPhone
          self.facilityContactEmail = fac.contactEmail
          self.facilitySlaHours = Int32(fac.slaResponseHours ?? 4)
          self.facilityHourlyRate = fac.contractHourlyRate
          self.facilityPartsMarkup = fac.partsMarkupPercent
      }

      self.lastUpdated = Date()
    }
}
