//
//  FleetAsset.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation

enum AssetType: String, Codable, CaseIterable {
    case van = "VAN"
    case craneTruck = "CRANE_TRUCK"
    case serviceTruck = "SERVICE_TRUCK"
    case recoveryTrailer = "RECOVERY_TRAILER"

    var title: String {
        switch self {
        case .van: return "Service Van"
        case .craneTruck: return "Crane Truck"
        case .serviceTruck: return "Heavy Truck"
        case .recoveryTrailer: return "Refrigerant Trailer"
        }
    }
}


enum AssetStatus: String, Codable, CaseIterable {
    case available = "AVAILABLE"
    case deployed = "DEPLOYED"
    case underMaintenance = "UNDER_MAINTENANCE"
}

struct FleetAsset: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let assetCode: String
    let name: String
    let assetType: AssetType
    let licensePlate: String
    let status: AssetStatus
}

struct FleetListResponse: Codable {
    let count: Int?
    let fleet: [FleetAsset]
}
