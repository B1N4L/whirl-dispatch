//
//  AttendanceView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-20.
//

import SwiftUI

struct AttendanceView: View {
    var authVM: AuthViewModel? = nil
    @State private var viewModel = AttendanceViewModel()
    @State private var offlineManager = OfflineModeManager.shared
    @State private var showingClockOutConfirmation = false
    @State private var showingTeamSiteMap = false

    private var isLeadOrSupervisor: Bool {
        if let role = authVM?.currentUser?.role {
            return role == .leadTechnician || role == .supervisor
        }
        return false
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // plant room offline cache banner
                    if offlineManager.isPlantRoomOffline {
                        OfflineBanner(
                            isOffline: true,
                            pendingCount: offlineManager.pendingSyncCount
                        ) {
                            Task {
                                await offlineManager.syncPendingChanges()
                            }
                        }
                    }

                    // error notification
                    if let err = viewModel.errorMessage {
                        ErrorBanner(message: err) {
                            viewModel.errorMessage = nil
                        }
                    }


                    // work order facility card
                    activeWorkplaceSiteSection

                    // View Employees Button for Lead Technician & Supervisor
                    if isLeadOrSupervisor, let order = viewModel.selectedWorkOrder {
                        Button(action: {
                            showingTeamSiteMap = true
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandNavy.opacity(0.12))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "person.3.sequence.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.brandNavy)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("View Employees on Site")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("Live geofence radar & crew location tracking")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.brandNavy.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                    }


                    // geofence anti-ghost clocking validation card
                    if let eval = viewModel.geofenceEvaluation {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: eval.isInside ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .font(.system(size: 18))
                                .foregroundColor(eval.isInside ? Color.statusGreen : Color.statusAmber)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(eval.isInside ? "On-Site Perimeter Verified (\(eval.formattedDistance))" : "Anti-Ghost Geofence Warning")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(eval.isInside ? Color.statusGreen : Color.statusAmber)

                                Text(eval.isInside
                                     ? "Within \(Int(eval.radiusMeters))m plant room boundary. Shift clock-in authorized."
                                     : "You are \(eval.formattedDistance) away. Anti-ghost clocking requires being within \(Int(eval.radiusMeters))m.")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)

                                // testing simulator buttons for emulator verification
                                HStack(spacing: 8) {
                                    if !eval.isInside {
                                        Button(action: {
                                            viewModel.simulateArrivalAtCurrentFacility()
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "location.north.circle.fill")
                                                Text("Simulate Site Arrival (Testing)")
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.accentBlue.opacity(0.12))
                                            .foregroundColor(Color.accentBlue)
                                            .cornerRadius(6)
                                        }
                                    } else {
                                        Button(action: {
                                            viewModel.simulateDepartureFromCurrentFacility()
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "location.slash.fill")
                                                Text("Simulate Leaving Site (Testing)")
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.statusAmber.opacity(0.15))
                                            .foregroundColor(Color.statusAmber)
                                            .cornerRadius(6)
                                        }
                                    }

                                    if viewModel.isSimulatedLocationActive {
                                        Button(action: {
                                            viewModel.resetSimulation()
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset GPS")
                                                    .font(.system(size: 11, weight: .semibold))
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color.secondary.opacity(0.12))
                                            .foregroundColor(.secondary)
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(eval.isInside ? Color.statusGreen.opacity(0.08) : Color.statusAmber.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(eval.isInside ? Color.statusGreen.opacity(0.3) : Color.statusAmber.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }


                    // central clock dial button
                    VStack(spacing: 12) {
                        ClockDialButton(
                            isClockedIn: viewModel.isClockedIn,
                            isOnBreak: viewModel.isOnBreak,
                            timeText: viewModel.formattedElapsedTime,
                            isLoading: viewModel.isLoading,
                            hasAssignedDispatch: viewModel.selectedWorkOrder != nil
                        ) {
                            if viewModel.isClockedIn {
                                showingClockOutConfirmation = true
                            } else {
                                Task {
                                    _ = await viewModel.clockIn()
                                }
                            }
                        }
                    }
                    .padding(.top, 10)


                    // break pause controls when clocked in
                    if viewModel.isClockedIn {
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    await viewModel.toggleBreak()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.isOnBreak ? "play.fill" : "pause.fill")
                                    Text(viewModel.isOnBreak ? "Resume Site Shift" : "Pause Shift for Break")
                                        .font(.appSubheadline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundColor(viewModel.isOnBreak ? .white : Color.brandNavy)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(viewModel.isOnBreak ? Color.statusAmber : Color.brandNavy.opacity(0.10))
                                )
                            }
                            .accessibilityLabel(viewModel.isOnBreak ? "Resume shift" : "Pause shift for break")

                            if viewModel.isOnBreak {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Break Elapsed")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(viewModel.formattedBreakTime)
                                        .font(.appMonoHeadline)
                                        .foregroundColor(Color.statusAmber)
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                    }


                    // today's shift tally card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Shift Summary")
                            .font(.appSubheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            summaryMetric(
                                label: "Total Billed",
                                value: viewModel.todayTotalHoursText,
                                icon: "clock.fill",
                                color: Color.accentBlue
                            )

                            summaryMetric(
                                label: "Session State",
                                value: viewModel.isClockedIn ? (viewModel.isOnBreak ? "On Break" : "Active") : "Off-Duty",
                                icon: "bolt.shield.fill",
                                color: viewModel.isClockedIn ? (viewModel.isOnBreak ? Color.statusAmber : Color.statusGreen) : Color.statusGray
                            )

                            summaryMetric(
                                label: "Plant Room Mode",
                                value: offlineManager.isPlantRoomOffline ? "Offline" : "Live Cloud",
                                icon: offlineManager.isPlantRoomOffline ? "shield.fill" : "cloud.fill",
                                color: offlineManager.isPlantRoomOffline ? Color.statusAmber : Color.statusGreen
                            )
                        }
                    }
                    .padding(.horizontal, 16)


                    // historical shift log ledger
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Shift History")
                            .font(.appSubheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        if viewModel.attendanceHistory.isEmpty {
                            Text("No previous site sessions recorded.")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.cardBackground)
                                )
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.attendanceHistory) { record in
                                    shiftHistoryRow(record: record)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Site Attendance")
            .task {
                LocationManager.shared.startUpdating()
                await viewModel.loadAttendanceData()
                viewModel.evaluateGeofence()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await viewModel.loadAttendanceData()
                    viewModel.evaluateGeofence()
                }
            }
            .sheet(isPresented: $showingTeamSiteMap) {
                if let order = viewModel.selectedWorkOrder {
                    TeamSiteMapView(workOrderId: order.id)
                }
            }
            .confirmationDialog(
                "Clock Out of Shift?",
                isPresented: $showingClockOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Confirm Clock-Out", role: .destructive) {
                    Task {
                        _ = await viewModel.clockOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your recorded labor time will be submitted and added to the billing ledger.")
            }
        }
    }


    // summary metric cell
    @ViewBuilder
    private func summaryMetric(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.appHeadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackground)
        )
    }


    // history log card row
    @ViewBuilder
    private func shiftHistoryRow(record: AttendanceRecord) -> some View {
      HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 3) {
              Text(record.formattedClockIn)
                  .font(.appSubheadline)
                  .fontWeight(.medium)
                  .foregroundColor(.primary)

              Text(record.formattedClockOut != nil ? "Clocked out: \(record.formattedClockOut!)" : "In Progress")
                  .font(.caption2)
                  .foregroundColor(.secondary)
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 4) {
              Text(record.billableHoursText)
                  .font(.appMono)
                  .fontWeight(.bold)
                  .foregroundColor(Color.brandNavy)

              Text(record.sessionStatus.title)
                  .font(.system(size: 9, weight: .bold))
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .foregroundColor(record.sessionStatus == .clockedOut ? Color.statusGreen : Color.statusAmber)
                  .background(
                      Capsule()
                          .fill((record.sessionStatus == .clockedOut ? Color.statusGreen : Color.statusAmber).opacity(0.12))
                  )
          }
      }
      .padding(14)
      .background(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.cardBackground)
      )
    }


    // MARK: - Active Workplace Site Section

    @ViewBuilder
    private var activeWorkplaceSiteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Workplace Site")
                .font(.appSubheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            if let order = viewModel.selectedWorkOrder {
                assignedSiteCard(for: order)
            } else {
                standbySiteCard
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func assignedSiteCard(for order: WorkOrder) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(order.workOrderNumber)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandNavy.opacity(0.12))
                            .foregroundColor(Color.brandNavy)
                            .cornerRadius(4)

                        Text(order.status.label)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    Text(order.facility?.facilityName ?? "Assigned Facility")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let address = order.facility?.address {
                        Text(address)
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isClockedIn ? "lock.fill" : "mappin.circle.fill")
                            .font(.caption)
                        Text(viewModel.isClockedIn ? "Active Shift" : "Assigned Site")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.isClockedIn ? Color.statusGreen : Color.brandNavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((viewModel.isClockedIn ? Color.statusGreen : Color.brandNavy).opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Divider()

            HStack {
                Text(viewModel.isClockedIn
                     ? "Facility locked to active shift in progress"
                     : (order.facility?.companyName ?? "Supervisor designated dispatch location"))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    Task {
                        await viewModel.loadAttendanceData()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2.bold())
                        Text("Refresh")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandNavy.opacity(0.08))
                    .foregroundColor(Color.brandNavy)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.surfaceBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var standbySiteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "607D8B").opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "455A64"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("No Active Dispatches")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("You are not currently scheduled for any work orders.")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack {
                Text("Awaiting dispatch assignment from supervisor or dispatcher.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    Task {
                        await viewModel.loadAttendanceData()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2.bold())
                        Text("Refresh")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brandNavy.opacity(0.1))
                    .foregroundColor(Color.brandNavy)
                    .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.surfaceBorder, lineWidth: 1)
        )
    }


}


#Preview {
    AttendanceView()
}
