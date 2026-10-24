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
