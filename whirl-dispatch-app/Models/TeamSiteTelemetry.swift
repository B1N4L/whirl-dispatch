//
//  TeamSiteTelemetry.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-28.
//

import Foundation
import CoreLocation

struct TeamMemberTelemetry: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let fullName: String
    let email: String
    let phone: String?
    let role: UserRole
    let isLead: Bool
    let isClockedIn: Bool
    let sessionStatus: String
    let clockInTimestamp: String?
    let latitude: Double
    let longitude: Double
    let isInsideGeofence: Bool
    let distanceToFacilityMeters: Double
    let formattedDistance: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
        return "\(first)\(last)".uppercased()
    }

    var statusDisplayTitle: String {
        switch sessionStatus {
        case "ACTIVE_ON_SITE", "CLOCKED_IN":
            return isInsideGeofence ? "Active On-Site" : "Clocked In (Outside)"
        case "BREAK_PAUSED", "ON_BREAK_VIOLATION":
            return "On Break"
        case "EN_ROUTE":
            return "En Route"
        case "CLOCKED_OUT":
            return "Shift Completed"
        default:
            return isClockedIn ? "Active" : "Dispatched"
        }
    }
}

struct TeamFacilityTelemetry: Codable, Equatable, Hashable {
    let id: String
    let companyName: String
    let facilityName: String
    let address: String
    let latitude: Double
    let longitude: Double
    let geofenceRadius: Double
    let contactPersonName: String?
    let contactPhone: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct TeamSiteTelemetryResponse: Codable, Equatable {
    let workOrderId: String
    let workOrderNumber: String
    let title: String
    let status: WorkOrderStatus
    let priority: WorkOrderPriority
    let facility: TeamFacilityTelemetry
    let team: [TeamMemberTelemetry]
    let totalCrewCount: Int
    let clockedInCount: Int
    let insideGeofenceCount: Int
}
