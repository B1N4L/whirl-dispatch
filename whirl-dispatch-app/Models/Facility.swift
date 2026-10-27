//
//  Facility.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation
import CoreLocation

struct Facility: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let companyName: String
    let facilityName: String
    let address: String
   let latitude: Double
   let longitude: Double
    let geofenceRadius: Double
    let contactPersonName: String
    let contactPhone: String
    let contactEmail: String?
   let slaResponseHours: Int?
    let contractHourlyRate: String?
    let partsMarkupPercent: String?

    init(
        id: String,
        companyName: String,
        facilityName: String,
        address: String,
        latitude: Double,
        longitude: Double,
        geofenceRadius: Double,
        contactPersonName: String,
        contactPhone: String,
        contactEmail: String? = nil,
        slaResponseHours: Int? = nil,
        contractHourlyRate: String? = nil,
        partsMarkupPercent: String? = nil
    ) {
        self.id = id
        self.companyName = companyName
        self.facilityName = facilityName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.geofenceRadius = geofenceRadius
        self.contactPersonName = contactPersonName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.slaResponseHours = slaResponseHours
        self.contractHourlyRate = contractHourlyRate
        self.partsMarkupPercent = partsMarkupPercent
    }

    enum CodingKeys: String, CodingKey {
        case id, companyName, facilityName, address, latitude, longitude
        case geofenceRadius, contactPersonName, contactPhone, contactEmail
        case slaResponseHours, contractHourlyRate, partsMarkupPercent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        companyName = try container.decode(String.self, forKey: .companyName)
        facilityName = try container.decode(String.self, forKey: .facilityName)
        address = try container.decode(String.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        geofenceRadius = try container.decode(Double.self, forKey: .geofenceRadius)
        contactPersonName = try container.decode(String.self, forKey: .contactPersonName)
        contactPhone = try container.decode(String.self, forKey: .contactPhone)
        contactEmail = try container.decodeIfPresent(String.self, forKey: .contactEmail)
        slaResponseHours = try container.decodeIfPresent(Int.self, forKey: .slaResponseHours)

        // safely handle string, double, or integer rates
        if let str = try? container.decodeIfPresent(String.self, forKey: .contractHourlyRate) {
            contractHourlyRate = str
        } else if let num = try? container.decodeIfPresent(Double.self, forKey: .contractHourlyRate) {
            contractHourlyRate = String(format: "%.2f", num)
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .contractHourlyRate) {
            contractHourlyRate = "\(intVal).00"
        } else {
            contractHourlyRate = nil
        }

        if let str = try? container.decodeIfPresent(String.self, forKey: .partsMarkupPercent) {
            partsMarkupPercent = str
        } else if let num = try? container.decodeIfPresent(Double.self, forKey: .partsMarkupPercent) {
            partsMarkupPercent = String(format: "%.2f", num)
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .partsMarkupPercent) {
            partsMarkupPercent = "\(intVal).00"
        } else {
            partsMarkupPercent = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(facilityName, forKey: .facilityName)
        try container.encode(address, forKey: .address)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(geofenceRadius, forKey: .geofenceRadius)
        try container.encode(contactPersonName, forKey: .contactPersonName)
        try container.encode(contactPhone, forKey: .contactPhone)
        try container.encodeIfPresent(contactEmail, forKey: .contactEmail)
        try container.encodeIfPresent(slaResponseHours, forKey: .slaResponseHours)
        try container.encodeIfPresent(contractHourlyRate, forKey: .contractHourlyRate)
        try container.encodeIfPresent(partsMarkupPercent, forKey: .partsMarkupPercent)
    }


    // convert to cllocation coordinate
    var coordinate: CLLocationCoordinate2D {
      CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    // display title for maps and cards
    var displayName: String {
       "\(companyName) - \(facilityName)"
    }
}


struct FacilityListResponse: Codable {
    let count: Int?
    let facilities: [Facility]
}
