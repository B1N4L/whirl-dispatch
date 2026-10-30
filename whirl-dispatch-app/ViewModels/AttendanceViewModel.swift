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

    // testing simulation states
    var isSimulatedLocationActive: Bool {
        locationManager.isSimulatedLocationActive
    }

    func simulateArrivalAtCurrentFacility() {
        guard let fac = selectedWorkOrder?.facility else { return }
        locationManager.simulateArrival(at: fac.coordinate)
        _ = evaluateGeofence()
    }

    func simulateDepartureFromCurrentFacility() {
        guard let fac = selectedWorkOrder?.facility else { return }
        locationManager.simulateDeparture(from: fac.coordinate)
        _ = evaluateGeofence()
    }

    func resetSimulation() {
        locationManager.resetSimulation()
        _ = evaluateGeofence()
    }

    // load work orders and check for active attendance
    func loadAttendanceData() async {
        isLoading = true
        errorMessage = nil

        // load dispatches to determine active workplace site (single active dispatch model)
        let (orders, _, _) = await WorkOrderRepository.shared.fetchWorkOrders()
        let activeOrders = orders.filter {
            $0.status == .onSiteActive || $0.status == .unacknowledgedBreak || $0.status == .awaitingPartsApproval || $0.status == .enRoute || $0.status == .dispatched
        }
        self.assignedWorkOrders = activeOrders

        if !isClockedIn || selectedWorkOrder == nil {
            // prioritize in-progress active work order, then first dispatched
            if let active = activeOrders.first(where: {
                $0.status == .onSiteActive || $0.status == .unacknowledgedBreak || $0.status == .awaitingPartsApproval || $0.status == .enRoute
            }) {
                self.selectedWorkOrder = active
            } else {
                self.selectedWorkOrder = activeOrders.first(where: { $0.status == .dispatched })
            }
        }

        var activeFound = false
        var remoteCheckCompleted = false

        // 1. Query remote active session if online
        if !offlineManager.isPlantRoomOffline {
            do {
                let currentRes: CurrentAttendanceResponse = try await apiService.send(.getCurrentAttendance)
                remoteCheckCompleted = true
                if currentRes.active, let active = currentRes.session {
                    self.currentSession = active
                    self.isClockedIn = true
                    self.isOnBreak = (active.sessionStatus == .onBreakViolation)

                    if let matchingOrder = orders.first(where: { $0.id == active.workOrderId }) {
                        self.selectedWorkOrder = matchingOrder
                    }

                    if let clockInDate = ISO8601DateFormatter().date(from: active.clockInTimestamp) {
                        let totalElapsed = Int(Date().timeIntervalSince(clockInDate))
                        self.elapsedSeconds = max(0, totalElapsed - active.totalBreakSeconds)
                    } else {
                        self.elapsedSeconds = active.totalBillableSeconds
                    }
                    self.breakSeconds = active.totalBreakSeconds
                    startTimer()
                    activeFound = true
                    await offlineStorage.upsertAttendance(active, isSyncPending: false)
                } else {
                    // Cloud returned active == false. Cloud is authoritative when online.
                    // Clean up any local orphaned non-pending active sessions.
                    await offlineStorage.clearOrphanedActiveAttendance()
                    self.currentSession = nil
                    self.isClockedIn = false
                    self.isOnBreak = false
                    self.elapsedSeconds = 0
                    self.breakSeconds = 0
                    stopTimer()
                }
            } catch {
                // fall through to local cache or timeline
            }
        }

        // 2. Fall back to local Core Data active session ONLY if offline or if remote check failed
        if !activeFound && (!remoteCheckCompleted || offlineManager.isPlantRoomOffline) {
            if let activeCached = await offlineStorage.fetchActiveCachedAttendance() {
                self.currentSession = activeCached
                self.isClockedIn = true
                self.isOnBreak = (activeCached.sessionStatus == .onBreakViolation)

                if let matchingOrder = orders.first(where: { $0.id == activeCached.workOrderId }) {
                    self.selectedWorkOrder = matchingOrder
                }

                if let clockInDate = ISO8601DateFormatter().date(from: activeCached.clockInTimestamp) {
                    let totalElapsed = Int(Date().timeIntervalSince(clockInDate))
                    self.elapsedSeconds = max(0, totalElapsed - activeCached.totalBreakSeconds)
                } else {
                    self.elapsedSeconds = activeCached.totalBillableSeconds
                }
                self.breakSeconds = activeCached.totalBreakSeconds
                startTimer()
                activeFound = true
            } else if let order = selectedWorkOrder, let cached = await offlineStorage.fetchCachedAttendance(workOrderId: order.id), cached.clockOutTimestamp == nil {
                self.currentSession = cached
                self.isClockedIn = true
                self.isOnBreak = (cached.sessionStatus == .onBreakViolation)

                if let clockInDate = ISO8601DateFormatter().date(from: cached.clockInTimestamp) {
                    let totalElapsed = Int(Date().timeIntervalSince(clockInDate))
                    self.elapsedSeconds = max(0, totalElapsed - cached.totalBreakSeconds)
                } else {
                    self.elapsedSeconds = cached.totalBillableSeconds
                }
                self.breakSeconds = cached.totalBreakSeconds
                startTimer()
                activeFound = true
            } else {
                self.currentSession = nil
                self.isClockedIn = false
                self.isOnBreak = false
                self.elapsedSeconds = 0
                self.breakSeconds = 0
                stopTimer()
            }
        }

        // 3. Load timeline history for the active or selected work order
        if let order = selectedWorkOrder {
            if !offlineManager.isPlantRoomOffline {
                do {
                    let res: AttendanceTimelineResponse = try await apiService.send(.getAttendanceHistory(workOrderId: order.id))
                    self.attendanceHistory = res.resolvedTimeline

                    if !self.isClockedIn, let openSession = res.resolvedTimeline.first(where: { $0.clockOutTimestamp == nil }) {
                        self.currentSession = openSession
                        self.isClockedIn = true
                        self.isOnBreak = (openSession.sessionStatus == .onBreakViolation)

                        if let clockInDate = ISO8601DateFormatter().date(from: openSession.clockInTimestamp) {
                            let totalElapsed = Int(Date().timeIntervalSince(clockInDate))
                            self.elapsedSeconds = max(0, totalElapsed - openSession.totalBreakSeconds)
                        } else {
                            self.elapsedSeconds = openSession.totalBillableSeconds
                        }
                        self.breakSeconds = openSession.totalBreakSeconds
                        startTimer()
                    }
                } catch {
                    // silently fall back if history endpoint returns 404
                }
            }
        }

        _ = evaluateGeofence()
        if isClockedIn, let woId = currentSession?.workOrderId ?? selectedWorkOrder?.id {
            let activeOrder = assignedWorkOrders.first(where: { $0.id == woId }) ?? selectedWorkOrder
            let fac = activeOrder?.facility
            LocationTelemetryService.shared.startTracking(
                workOrderId: woId,
                facilityName: fac?.facilityName,
                facilityCoordinate: fac?.coordinate,
                geofenceRadius: fac?.geofenceRadius
            )
        } else {
            LocationTelemetryService.shared.stopTracking()
        }

        // Sync any break toggle initiated from home screen widget intent
        let widgetSnapshot = ShiftWidgetSnapshot.load()
        if isClockedIn, widgetSnapshot.pendingBreakSync == true {
            self.isOnBreak = widgetSnapshot.isOnBreak
            var updatedSnap = widgetSnapshot
            updatedSnap.pendingBreakSync = false
            updatedSnap.save()

            if let order = selectedWorkOrder, !offlineManager.isPlantRoomOffline {
                let lat = order.facility?.latitude ?? 6.9175
                let lng = order.facility?.longitude ?? 79.8580
                Task {
                    let _: BoundaryEventResponse? = try? await apiService.send(.pauseBreak(workOrderId: order.id, lat: lat, lng: lng))
                }
            }
        }

        syncWidgetState()
        isLoading = false
    }

    func selectWorkOrder(_ order: WorkOrder) async {
        guard !isClockedIn else { return }
        self.selectedWorkOrder = order
        _ = evaluateGeofence()

        if !offlineManager.isPlantRoomOffline {
            do {
                let res: AttendanceTimelineResponse = try await apiService.send(.getAttendanceHistory(workOrderId: order.id))
                self.attendanceHistory = res.resolvedTimeline
            } catch {
                self.attendanceHistory = []
            }
        }
        syncWidgetState()
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

        if isClockedIn {
            LocationTelemetryService.shared.checkGeofenceBreach(
                userCoordinate: locationManager.effectiveCoordinate,
                isOnBreak: isOnBreak
            )
        }

        return eval
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
          LocationTelemetryService.shared.startTracking(
              workOrderId: order.id,
              facilityName: order.facility?.facilityName,
              facilityCoordinate: order.facility?.coordinate,
              geofenceRadius: order.facility?.geofenceRadius
          )
          syncWidgetState()
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
          LocationTelemetryService.shared.startTracking(
              workOrderId: order.id,
              facilityName: order.facility?.facilityName,
              facilityCoordinate: order.facility?.coordinate,
              geofenceRadius: order.facility?.geofenceRadius
          )
          syncWidgetState()
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
        let targetWorkOrderId = currentSession?.workOrderId ?? order.id

        isLoading = true
        errorMessage = nil

        let targetFacility = assignedWorkOrders.first(where: { $0.id == targetWorkOrderId })?.facility ?? order.facility
        let lat = targetFacility?.latitude ?? 6.9175
        let lng = targetFacility?.longitude ?? 79.8580

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
            self.elapsedSeconds = 0
            self.breakSeconds = 0
            stopTimer()
            LocationTelemetryService.shared.stopTracking()
            let historicalSeconds = attendanceHistory.reduce(0) { $0 + $1.totalBillableSeconds }
            let hours = Double(historicalSeconds) / 3600.0
            WidgetSyncManager.shared.syncClockOut(
                todayTotalHours: hours,
                workOrderNumber: selectedWorkOrder?.workOrderNumber,
                workOrderTitle: selectedWorkOrder?.title,
                facilityName: selectedWorkOrder?.facility?.facilityName
            )
            isLoading = false
            return true
        }

        do {
            let res: ClockOutResponse = try await apiService.send(.clockOut(workOrderId: targetWorkOrderId, lat: lat, lng: lng))
            self.attendanceHistory.insert(res.session, at: 0)
            await offlineStorage.upsertAttendance(res.session, isSyncPending: false)
            self.isClockedIn = false
            self.isOnBreak = false
            self.currentSession = nil
            self.elapsedSeconds = 0
            self.breakSeconds = 0
            stopTimer()
            LocationTelemetryService.shared.stopTracking()
            let historicalSeconds = attendanceHistory.reduce(0) { $0 + $1.totalBillableSeconds }
            let hours = Double(historicalSeconds) / 3600.0
            WidgetSyncManager.shared.syncClockOut(
                todayTotalHours: hours,
                workOrderNumber: selectedWorkOrder?.workOrderNumber,
                workOrderTitle: selectedWorkOrder?.title,
                facilityName: selectedWorkOrder?.facility?.facilityName
            )
            isLoading = false
            return true
        } catch let apiErr as APIError {
            // Self-healing: If server responded with 404 (no active session found on server),
            // clean up the local desynchronized state so the timer stops and the user is unblocked.
            if case .notFound = apiErr {
                await offlineStorage.clearOrphanedActiveAttendance()
                self.isClockedIn = false
                self.isOnBreak = false
                self.currentSession = nil
                self.elapsedSeconds = 0
                self.breakSeconds = 0
                stopTimer()
                LocationTelemetryService.shared.stopTracking()
                let historicalSeconds = attendanceHistory.reduce(0) { $0 + $1.totalBillableSeconds }
                let hours = Double(historicalSeconds) / 3600.0
                WidgetSyncManager.shared.syncClockOut(
                    todayTotalHours: hours,
                    workOrderNumber: selectedWorkOrder?.workOrderNumber,
                    workOrderTitle: selectedWorkOrder?.title,
                    facilityName: selectedWorkOrder?.facility?.facilityName
                )
                isLoading = false
                errorMessage = "Shift was already closed or not active on the server. Local shift timer has been reset."
                return true
            }

            isLoading = false
            errorMessage = apiErr.localizedDescription
            return false
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
      syncWidgetState()

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


    // sync shift state to home screen widget
    func syncWidgetState() {
        let clockInDate: Date? = isClockedIn ? currentSession.flatMap { ISO8601DateFormatter().date(from: $0.clockInTimestamp) } : nil
        let historicalSeconds = attendanceHistory.reduce(0) { $0 + $1.totalBillableSeconds }
        let total = historicalSeconds + (isClockedIn ? elapsedSeconds : 0)
        let hours = Double(total) / 3600.0

        WidgetSyncManager.shared.syncShift(
            isClockedIn: isClockedIn,
            isOnBreak: isOnBreak,
            clockInDate: clockInDate,
            totalBreakSeconds: isClockedIn ? breakSeconds : 0,
            workOrderNumber: selectedWorkOrder?.workOrderNumber,
            workOrderTitle: selectedWorkOrder?.title,
            facilityName: selectedWorkOrder?.facility?.facilityName,
            todayTotalHours: hours
        )
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
