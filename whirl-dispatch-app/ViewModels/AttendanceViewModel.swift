//
//  AttendanceViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-20.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class AttendanceViewModel {
    var currentSession: AttendanceRecord? = nil
    var isClockedIn: Bool = false
    var isOnBreak: Bool = false
    var elapsedSeconds: Int = 0
    var breakSeconds: Int = 0

    var selectedWorkOrder: WorkOrder? = nil
    var assignedWorkOrders: [WorkOrder] = []
    var attendanceHistory: [AttendanceRecord] = []

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var geofenceEvaluation: GeofenceEvaluation? = nil

    private var shiftTimer: Timer? = nil
    private let apiService: APIService
    private let offlineStorage: OfflineStorageService
    private let offlineManager: OfflineModeManager
    private let locationManager: LocationManager
    private let geofenceService: GeofenceService

    init(
        apiService: APIService? = nil,
        offlineStorage: OfflineStorageService? = nil,
        offlineManager: OfflineModeManager? = nil,
        locationManager: LocationManager? = nil,
        geofenceService: GeofenceService? = nil
    ) {
        self.apiService = apiService ?? .shared
        self.offlineStorage = offlineStorage ?? .shared
        self.offlineManager = offlineManager ?? .shared
        self.locationManager = locationManager ?? .shared
        self.geofenceService = geofenceService ?? .shared
    }


    // formatted hours minutes seconds for timer dial
    var formattedElapsedTime: String {
      let hours = elapsedSeconds / 3600
      let minutes = (elapsedSeconds % 3600) / 60
      let seconds = elapsedSeconds % 60
      return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // formatted break duration text
    var formattedBreakTime: String {
        let minutes = breakSeconds / 60
        let seconds = breakSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // tally of total billable hours today
    var todayTotalHoursText: String {
        let historicalSeconds = attendanceHistory.reduce(0) { $0 + $1.totalBillableSeconds }
        let total = historicalSeconds + (isClockedIn ? elapsedSeconds : 0)
        let hours = Double(total) / 3600.0
        return String(format: "%.1f hrs", hours)
    }


    // load work orders and check for active attendance
    func loadAttendanceData() async {
        isLoading = true
        errorMessage = nil

        // load dispatches to pick which facility we are clocking into
        let (orders, _, _) = await WorkOrderRepository.shared.fetchWorkOrders()
        self.assignedWorkOrders = orders

        if selectedWorkOrder == nil {
            // prioritize on-site or en-route work order
            self.selectedWorkOrder = orders.first(where: { $0.status == .onSiteActive || $0.status == .enRoute }) ?? orders.first
        }

        // restore active session if present locally
        if let order = selectedWorkOrder {
            if let cached = await offlineStorage.fetchCachedAttendance(workOrderId: order.id) {
                if cached.clockOutTimestamp == nil {
                    self.currentSession = cached
                    self.isClockedIn = true
                    self.isOnBreak = (cached.sessionStatus == .onBreakViolation)
                    self.elapsedSeconds = cached.totalBillableSeconds
                    startTimer()
                }
            }

            // fetch remote timeline if connected
            if !offlineManager.isPlantRoomOffline {
                do {
                    let res: AttendanceTimelineResponse = try await apiService.send(.getAttendanceHistory(workOrderId: order.id))
                    self.attendanceHistory = res.resolvedTimeline
                } catch {
                    // silently fall back if history endpoint returns 404
                }
            }
        }

        isLoading = false
    }


    // evaluate technician distance against active facility geofence
    @discardableResult
    func evaluateGeofence() -> GeofenceEvaluation? {
        guard let order = selectedWorkOrder, let facility = order.facility else {
            geofenceEvaluation = nil
            return nil
        }

        let eval = geofenceService.evaluate(
            userCoordinate: locationManager.effectiveCoordinate,
            facilityCoordinate: facility.coordinate,
            radiusMeters: facility.geofenceRadius
        )
        self.geofenceEvaluation = eval
        return eval
    }

    func simulateArrivalAtCurrentFacility() {
        guard let fac = selectedWorkOrder?.facility else { return }
        locationManager.simulateArrival(at: fac.coordinate)
        _ = evaluateGeofence()
    }

    func resetSimulation() {
        locationManager.resetSimulation()
        _ = evaluateGeofence()
    }


    // clock in to facility job site with anti-ghost clocking validation
    func clockIn() async -> Bool {
      guard let order = selectedWorkOrder else {
          errorMessage = "Please select an assigned work order before clocking in."
          return false
      }

      // anti-ghost clocking geofence verification
      let eval = evaluateGeofence()
      if let eval = eval, !eval.isInside {
          let facilityName = order.facility?.facilityName ?? "the commercial facility"
          errorMessage = "Anti-Ghost Clocking Violation: You are \(eval.formattedDistance) away from \(facilityName). You must be within the \(Int(eval.radiusMeters))m perimeter to start shift."
          return false
      }

      isLoading = true
      errorMessage = nil

      let techCoord = locationManager.effectiveCoordinate
      let lat = techCoord.latitude
      let lng = techCoord.longitude

      if offlineManager.isPlantRoomOffline {
          // record offline clock in locally in core data
          let nowStr = ISO8601DateFormatter().string(from: Date())
          let localRecord = AttendanceRecord(
              id: UUID().uuidString,
              workOrderId: order.id,
              technicianId: "current-user",
              clockInTimestamp: nowStr,
              clockOutTimestamp: nil,
              totalBillableSeconds: 0,
              totalBreakSeconds: 0,
              sessionStatus: .activeOnSite
          )

          await offlineStorage.upsertAttendance(localRecord, isSyncPending: true)
          self.currentSession = localRecord
          self.isClockedIn = true
          self.elapsedSeconds = 0
          self.breakSeconds = 0
          startTimer()
          isLoading = false
          return true
      }

      do {
          let res: ClockInResponse = try await apiService.send(.clockIn(workOrderId: order.id, lat: lat, lng: lng))
          self.currentSession = res.session
          self.isClockedIn = true
          self.elapsedSeconds = 0
          self.breakSeconds = 0
          await offlineStorage.upsertAttendance(res.session, isSyncPending: false)
          startTimer()
          isLoading = false
          return true
      } catch let apiErr as APIError {
          isLoading = false
          errorMessage = apiErr.localizedDescription
          return false
      } catch {
          isLoading = false
          errorMessage = error.localizedDescription
          return false
      }
    }


    // clock out from active job shift
    func clockOut() async -> Bool {
        guard let order = selectedWorkOrder else { return false }

        isLoading = true
        errorMessage = nil

        let lat = order.facility?.latitude ?? 6.9175
        let lng = order.facility?.longitude ?? 79.8580

        if offlineManager.isPlantRoomOffline {
            // mark attendance as completed locally
            if var session = currentSession {
                let nowStr = ISO8601DateFormatter().string(from: Date())
                session.clockOutTimestamp = nowStr
                session.totalBillableSeconds = elapsedSeconds
                session.totalBreakSeconds = breakSeconds
                session.sessionStatus = .clockedOut

                await offlineStorage.upsertAttendance(session, isSyncPending: true)
                self.attendanceHistory.insert(session, at: 0)
            }

            self.isClockedIn = false
            self.isOnBreak = false
            self.currentSession = nil
            stopTimer()
            isLoading = false
            return true
        }

        do {
            let res: ClockOutResponse = try await apiService.send(.clockOut(workOrderId: order.id, lat: lat, lng: lng))
            self.attendanceHistory.insert(res.session, at: 0)
            self.isClockedIn = false
            self.isOnBreak = false
            self.currentSession = nil
            stopTimer()
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }


    // toggle break pause
    func toggleBreak() async {
      guard isClockedIn, let order = selectedWorkOrder else { return }

      isOnBreak.toggle()

      if !offlineManager.isPlantRoomOffline {
          let lat = order.facility?.latitude ?? 6.9175
          let lng = order.facility?.longitude ?? 79.8580
          do {
              let _: BoundaryEventResponse = try await apiService.send(.pauseBreak(workOrderId: order.id, lat: lat, lng: lng))
          } catch {
              // ignore break logging network hiccups
          }
      }
    }


    // timer management
    private func startTimer() {
        stopTimer()
        shiftTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isClockedIn else { return }
                if self.isOnBreak {
                    self.breakSeconds += 1
                } else {
                    self.elapsedSeconds += 1
                }
            }
        }
    }

    private func stopTimer() {
        shiftTimer?.invalidate()
        shiftTimer = nil
    }
}
