//
//  TrackedSite.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-27.
//

import Foundation
import CoreLocation

struct TrackedFacility: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let companyName: String
    let facilityName: String
    let address: String
    let latitude: Double
    let longitude: Double
    let geofenceRadius: Double
    let contactPersonName: String?
    let contactPhone: String?
    let slaResponseHours: Int?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        "\(companyName) - \(facilityName)"
    }
}

struct TrackedTechnician: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let fullName: String
    let email: String
    let phone: String?
    let role: String?

    var initials: String {
        let parts = fullName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }
}

struct TrackedTeam: Codable, Equatable, Hashable {
    let leadTechnician: TrackedTechnician?
    let crew: [TrackedTechnician]
    let totalHeadcount: Int

    var summaryText: String {
        if let lead = leadTechnician {
            if crew.isEmpty {
                return "Lead: \(lead.fullName)"
            } else {
                return "Lead: \(lead.fullName) (+\(crew.count) crew)"
            }
        }
        return "\(totalHeadcount) technicians deployed"
    }
}

struct SiteTelemetry: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
    let isInsideGeofence: Bool
    let distanceToFacilityMeters: Double
    let formattedDistance: String
    let lastPingTimestamp: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct TrackedSite: Identifiable, Codable, Equatable, Hashable {
    var id: String { workOrderId }
    let workOrderId: String
    let workOrderNumber: String
    let title: String
    let description: String
    let status: WorkOrderStatus
    let priority: WorkOrderPriority
    let scheduledStartTime: String?
    let scheduledEndTime: String?
    let facility: TrackedFacility
    let team: TrackedTeam
    let vehicle: FleetAsset?
    let telemetry: SiteTelemetry

    var isEmergency: Bool {
        priority == .criticalEmergency
    }

    var isOnSite: Bool {
        status == .onSiteActive || status == .unacknowledgedBreak || status == .awaitingPartsApproval
    }

    var isEnRoute: Bool {
        status == .enRoute
    }

    var isDispatched: Bool {
        status == .dispatched
    }

    var statusColorName: String {
        if isOnSite { return "statusGreen" }
        if isEnRoute { return "accentBlue" }
        return "statusAmber"
    }
}

struct FleetTrackingResponse: Codable {
    let count: Int?
    let trackedSites: [TrackedSite]
}
