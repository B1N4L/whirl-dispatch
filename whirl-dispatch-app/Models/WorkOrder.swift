//
//  WorkOrder.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation

enum WorkOrderPriority: String, Codable, CaseIterable, Hashable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case criticalEmergency = "CRITICAL_EMERGENCY"

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Standard"
        case .high: return "High"
        case .criticalEmergency: return "Emergency"
        }
    }
}


enum WorkOrderStatus: String, Codable, CaseIterable, Hashable {
    case dispatched = "DISPATCHED"
    case enRoute = "EN_ROUTE"
    case onSiteActive = "ON_SITE_ACTIVE"
    case unacknowledgedBreak = "UNACKNOWLEDGED_BREAK"
    case awaitingPartsApproval = "AWAITING_PARTS_APPROVAL"
    case completed = "COMPLETED"
    case billed = "BILLED"
    case cancelled = "CANCELLED"

   var label: String {
       switch self {
       case .dispatched: return "Dispatched"
       case .enRoute: return "En Route"
       case .onSiteActive: return "Active On-Site"
       case .unacknowledgedBreak: return "On Break"
       case .awaitingPartsApproval: return "Parts Approval"
       case .completed: return "Completed"
       case .billed: return "Billed"
       case .cancelled: return "Cancelled"
       }
   }
}


struct WorkOrder: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let workOrderNumber: String
    let clientFacilityId: String
    let supervisorId: String
   let leadTechnicianId: String
    let assignedFleetAssetId: String?
    let title: String
    let description: String
    let priority: WorkOrderPriority
    var status: WorkOrderStatus
    let scheduledStartTime: String
    let scheduledEndTime: String
    let actualStartTime: String?
   let actualEndTime: String?

    // optional expanded relation when populated by backend
    var facility: Facility?

    // formatted display helpers
    var isEmergency: Bool {
      priority == .criticalEmergency
    }

    var canClockIn: Bool {
        status == .dispatched || status == .enRoute
    }
}
