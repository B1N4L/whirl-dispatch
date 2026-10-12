//
//  CachedFacility.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-12.
//

import Foundation
import CoreData

@objc(CachedFacility)
public class CachedFacility: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var companyName: String?
    @NSManaged public var facilityName: String?
    @NSManaged public var address: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var geofenceRadius: Double
    @NSManaged public var contactPersonName: String?
    @NSManaged public var contactPhone: String?
    @NSManaged public var contactEmail: String?
    @NSManaged public var slaResponseHours: Int32
    @NSManaged public var contractHourlyRate: String?
    @NSManaged public var partsMarkupPercent: String?


    // map to domain facility dto
    func toDomain() -> Facility {
        Facility(
            id: id,
            companyName: companyName ?? "Unknown Client",
            facilityName: facilityName ?? "Main Plant Room",
            address: address ?? "",
            latitude: latitude,
            longitude: longitude,
            geofenceRadius: geofenceRadius > 0 ? geofenceRadius : 150.0,
            contactPersonName: contactPersonName ?? "Facility Manager",
            contactPhone: contactPhone ?? "+1 (555) 000-0000",
            contactEmail: contactEmail,
            slaResponseHours: Int(slaResponseHours),
            contractHourlyRate: contractHourlyRate,
            partsMarkupPercent: partsMarkupPercent
        )
    }

    // populate from domain object
    func update(from facility: Facility) {
      self.id = facility.id
      self.companyName = facility.companyName
      self.facilityName = facility.facilityName
      self.address = facility.address
      self.latitude = facility.latitude
      self.longitude = facility.longitude
      self.geofenceRadius = facility.geofenceRadius
      self.contactPersonName = facility.contactPersonName
      self.contactPhone = facility.contactPhone
      self.contactEmail = facility.contactEmail
      self.slaResponseHours = Int32(facility.slaResponseHours ?? 4)
      self.contractHourlyRate = facility.contractHourlyRate
      self.partsMarkupPercent = facility.partsMarkupPercent
    }
}
