//
//  AttendanceRecord.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation

enum SessionStatus: String, Codable, CaseIterable {
    case clockedIn = "CLOCKED_IN"
    case activeOnSite = "ACTIVE_ON_SITE"
    case onBreakViolation = "ON_BREAK_VIOLATION"
    case clockedOut = "CLOCKED_OUT"

   var title: String {
       switch self {
       case .clockedIn: return "Clocked In"
       case .activeOnSite: return "Active On-Site"
       case .onBreakViolation: return "Break Violation"
       case .clockedOut: return "Clocked Out"
       }
   }
}


struct AttendanceRecord: Identifiable, Codable, Equatable {
    let id: String
    let workOrderId: String
    let technicianId: String
    let clockInTimestamp: String
    var clockOutTimestamp: String?
   var totalBillableSeconds: Int
   var totalBreakSeconds: Int
    var sessionStatus: SessionStatus

    // helper for display hours
    var billableHoursText: String {
      let hours = Double(totalBillableSeconds) / 3600.0
      return String(format: "%.1f hrs", hours)
    }

    var isCurrentlyOnSite: Bool {
        sessionStatus == .activeOnSite || sessionStatus == .clockedIn
    }
}


// response wrappers for attendance endpoints
struct ClockInResponse: Codable {
    let message: String?
    let session: AttendanceRecord
}

struct ClockOutResponse: Codable {
    let message: String?
    let session: AttendanceRecord
}

struct AttendanceTimelineResponse: Codable {
    let workOrderId: String?
    let count: Int?
    let sessions: [AttendanceRecord]?
    let timeline: [AttendanceRecord]?
    let totalRecordedHours: Double?

    var resolvedTimeline: [AttendanceRecord] {
        sessions ?? timeline ?? []
    }
}

struct BoundaryEventResponse: Codable {
    let message: String?
    let sessionStatus: String?
}


enum GeofenceEventType: String, Codable {
    case geofenceEnter = "GEOFENCE_ENTER"
    case geofenceExitBreach = "GEOFENCE_EXIT_BREACH"
    case breakPaused = "BREAK_PAUSED"
    case biometricReauthResume = "BIOMETRIC_REAUTH_RESUME"
    case supervisorOverride = "SUPERVISOR_OVERRIDE"
}

struct GeofenceAuditLog: Identifiable, Codable, Equatable {
    let id: String
    let workOrderId: String
    let technicianId: String
    let siteAttendanceId: String?
    let eventType: GeofenceEventType
   let recordedTimestamp: String
    let deviceLatitude: Double
    let deviceLongitude: Double
    let accuracyMeters: Double
    let isTamperVerified: Bool
    let notes: String?
}
