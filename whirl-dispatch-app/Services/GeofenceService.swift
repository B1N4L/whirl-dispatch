//
//  GeofenceService.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-25.
//

import Foundation
import CoreLocation

struct GeofenceEvaluation: Equatable {
    let isInside: Bool
    let distanceMeters: Double
    let radiusMeters: Double

    var formattedDistance: String {
        if distanceMeters < 1000.0 {
            return String(format: "%.0fm", distanceMeters)
        } else {
            return String(format: "%.1fkm", distanceMeters / 1000.0)
        }
    }
}


final class GeofenceService: @unchecked Sendable {
    static let shared = GeofenceService()

    private let earthRadiusMeters: Double = 6371000.0
    static let defaultPerimeterRadius: Double = 150.0 // 150 meters standard anti-ghost perimeter

    private init() {}


    // haversine formula calculating spherical surface distance between coordinates
    func calculateDistance(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Double {
      let lat1 = source.latitude * .pi / 180.0
      let lon1 = source.longitude * .pi / 180.0
      let lat2 = destination.latitude * .pi / 180.0
      let lon2 = destination.longitude * .pi / 180.0

      let dLat = lat2 - lat1
      let dLon = lon2 - lon1

      let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
              cos(lat1) * cos(lat2) * sin(dLon / 2.0) * sin(dLon / 2.0)

      let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
      return earthRadiusMeters * c
    }


    // evaluate if technician is within plant room facility geofence
    func evaluate(
        userCoordinate: CLLocationCoordinate2D,
        facilityCoordinate: CLLocationCoordinate2D,
        radiusMeters: Double = defaultPerimeterRadius
    ) -> GeofenceEvaluation {
        let distance = calculateDistance(from: userCoordinate, to: facilityCoordinate)
        let isInside = distance <= radiusMeters

        return GeofenceEvaluation(
            isInside: isInside,
            distanceMeters: distance,
            radiusMeters: radiusMeters
        )
    }
}
