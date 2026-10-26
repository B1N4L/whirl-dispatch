//
//  WorkOrderDetailView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-19.
//

import SwiftUI
import UIKit

struct WorkOrderDetailView: View {
    @State var order: WorkOrder
    var viewModel: WorkOrdersViewModel

    @State private var isPerformingTransition = false
    @State private var showingCompleteAlert = false
    @State private var showingRestrictionAlert = false
    @State private var showingDossierSheet = false
    @State private var actionErrorMessage: String? = nil
    @State private var offlineManager = OfflineModeManager.shared
    @State private var calendarSyncService = CalendarSyncService.shared
    @State private var calendarSyncToast: String? = nil


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if let toast = calendarSyncToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.statusGreen)
                        Text(toast)
                            .font(.appCaption)
                        Spacer()
                        Button(action: { calendarSyncToast = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.statusGreen.opacity(0.12))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }

                // order status and priority header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.workOrderNumber)
                            .font(.appMonoHeadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        Text(order.title)
                            .font(.appTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        PriorityBadge(priority: order.priority.toPriorityLevel)
                        StatusBadge(status: order.status.toStatusType)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)


                // lifecycle state transition progress track
                HStack(spacing: 4) {
                    stepIndicator(title: "Dispatched", isDone: true, isActive: order.status == .dispatched)
                    stepConnector(isDone: order.status != .dispatched)
                    stepIndicator(title: "En Route", isDone: order.status == .enRoute || order.status == .onSiteActive || order.status == .completed, isActive: order.status == .enRoute)
                    stepConnector(isDone: order.status == .onSiteActive || order.status == .completed)
                    stepIndicator(title: "On-Site", isDone: order.status == .onSiteActive || order.status == .completed, isActive: order.status == .onSiteActive)
                    stepConnector(isDone: order.status == .completed)
                    stepIndicator(title: "Done", isDone: order.status == .completed, isActive: order.status == .completed)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)


                // error banner if transition failed
                if let err = actionErrorMessage {
                    ErrorBanner(message: err) {
                        actionErrorMessage = nil
                    }
                }


                // work description block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Service Requirements")
                        .font(.appSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Text(order.description.isEmpty ? "No special diagnostic instructions provided." : order.description)
                        .font(.appBody)
                        .foregroundColor(.primary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cardBackground)
                        )
                }
                .padding(.horizontal, 16)


                // client facility and site contacts card
                if let fac = order.facility {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Facility & Access Information")
                            .font(.appSubheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fac.facilityName)
                                        .font(.appHeadline)
                                        .fontWeight(.bold)
                                    Text(fac.companyName)
                                        .font(.appSubheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                StatusBadge(status: .dispatched)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(Color.accentBlue)
                                    .padding(.top, 2)
                                Text(fac.address)
                                    .font(.appBody)
                                    .foregroundColor(.primary)
                            }

                            Divider()

                            // contact person and direct call trigger
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fac.contactPersonName)
                                        .font(.appSubheadline)
                                        .fontWeight(.medium)
                                    Text(fac.contactPhone)
                                        .font(.appCaption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if let phoneUrl = URL(string: "tel://\(fac.contactPhone.replacingOccurrences(of: " ", with: ""))") {
                                    Link(destination: phoneUrl) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "phone.fill")
                                            Text("Call")
                                        }
                                        .font(.appSubheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.statusGreen)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.cardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        )
                    }
                    .padding(.horizontal, 16)
                }


                // equipment specs & schedule times
                VStack(alignment: .leading, spacing: 10) {
                    Text("Equipment & Schedule")
                        .font(.appSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        specRow(label: "Scheduled Window", value: "\(order.scheduledStartTime) to \(order.scheduledEndTime)")
                        specRow(label: "Lead Technician ID", value: order.leadTechnicianId)
                        if let assetId = order.assignedFleetAssetId {
                            specRow(label: "Fleet Van Unit", value: assetId)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.cardBackground)
                    )
                }
                .padding(.horizontal, 16)


                // diagnostic machinery dossier & proof button
                VStack(spacing: 8) {
                    Button(action: {
                        showingDossierSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.image.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.brandNavy)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Diagnostic Dossier & Checklist")
                                    .font(.appHeadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("Inspect HVAC pressures, motor amps & diagnostic items")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.surfaceBorder, lineWidth: 1)
                        )
                        .accessibilityLabel("Diagnostic Machinery Dossier & Checklist")
                        .accessibilityHint("Double tap to inspect HVAC baseline metrics and capture damage photos.")
                    }
                }
                .padding(.horizontal, 16)


                // native ios calendar sync card
                calendarSyncCard


                // option b: shielded plant room offline mode toggle
                VStack(alignment: .leading, spacing: 10) {
                    Text("Plant Room Connectivity")
                        .font(.appSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center) {
                            Image(systemName: offlineManager.isPlantRoomOffline ? "shield.fill" : "antenna.radiowaves.left.and.right")
                                .font(.system(size: 22))
                                .foregroundColor(offlineManager.isPlantRoomOffline ? Color.statusAmber : Color.accentBlue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shielded Plant Room Mode")
                                    .font(.appHeadline)
                                    .fontWeight(.semibold)

                                Text(offlineManager.isPlantRoomOffline ? "Operating in local Core Data cache" : "Connected to Live Vercel API")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { offlineManager.isPlantRoomOffline },
                                set: { newValue in
                                    let success = offlineManager.setPlantRoomOffline(enabled: newValue, for: order)
                                    if !success {
                                        showingRestrictionAlert = true
                                    } else {
                                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                                        haptic.impactOccurred()
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(Color.statusAmber)
                            .accessibilityLabel("Shielded Plant Room Mode")
                            .accessibilityValue(offlineManager.isPlantRoomOffline ? "Enabled" : "Disabled")
                            .accessibilityHint("Requires active on-site status. Toggles subterranean Core Data caching.")
                        }

                        if order.status != .onSiteActive && !offlineManager.isPlantRoomOffline {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("Requires active on-site status to activate offline mode.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.cardBackground)
                    )
                }
                .padding(.horizontal, 16)


                // lifecycle state transition action bar
                VStack(spacing: 12) {
                    actionButtonForCurrentState()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Complete Work Order?",
            isPresented: $showingCompleteAlert,
            titleVisibility: .visible
        ) {
            Button("Confirm Job Completion", role: .none) {
                performTransition(to: .completed)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Confirm that all mechanical diagnostic checks and plant room cleaning are done.")
        }
        .alert("Offline Mode Restricted", isPresented: $showingRestrictionAlert) {
            Button("Understood", role: .cancel) {}
        } message: {
            Text(offlineManager.restrictionErrorMessage ?? "You cannot enable offline mode outside the workplace site. You must arrive and clock in on-site first.")
        }
        .sheet(isPresented: $showingDossierSheet) {
            DiagnosticDossierView(workOrder: order)
        }
    }


    // dynamic action button based on state machine
    @ViewBuilder
    private func actionButtonForCurrentState() -> some View {
      switch order.status {
      case .dispatched:
          PrimaryButton(
              title: "Accept & Start Travel",
              icon: "car.fill",
              isLoading: isPerformingTransition
          ) {
              performTransition(to: .enRoute)
          }

      case .enRoute:
          PrimaryButton(
              title: "Arrive On-Site & Clock In",
              icon: "location.fill",
              isLoading: isPerformingTransition
          ) {
              performTransition(to: .onSiteActive)
          }

      case .onSiteActive, .unacknowledgedBreak, .awaitingPartsApproval:
          PrimaryButton(
              title: "Complete Maintenance Job",
              icon: "checkmark.circle.fill",
              isLoading: isPerformingTransition
          ) {
              showingCompleteAlert = true
          }

      case .completed, .billed:
          HStack {
              Image(systemName: "checkmark.seal.fill")
                  .foregroundColor(Color.statusGreen)
              Text("Job Completed & Ready for Billing")
                  .font(.appSubheadline)
                  .fontWeight(.semibold)
                  .foregroundColor(Color.statusGreen)
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .fill(Color.statusGreen.opacity(0.12))
          )

      case .cancelled:
          Text("Work Order Cancelled")
              .font(.appSubheadline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
      }
    }


    // execute state transition via viewmodel
    private func performTransition(to newStatus: WorkOrderStatus) {
        isPerformingTransition = true
        actionErrorMessage = nil

        let haptic = UINotificationFeedbackGenerator()
        haptic.prepare()

        Task {
            let success = await viewModel.transitionStatus(order: order, to: newStatus)
            if success {
                haptic.notificationOccurred(.success)
                order.status = newStatus
            } else {
                haptic.notificationOccurred(.error)
                actionErrorMessage = "Failed to update work order status on server. Change saved offline."
            }
            isPerformingTransition = false
        }
    }


    private var calendarSyncCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("iOS Calendar Integration", systemImage: "calendar.badge.clock")
                    .font(.appSubheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                if calendarSyncService.isOrderSynced(order.id) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.statusGreen)
                        Text("Synced")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.statusGreen)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.statusGreen.opacity(0.12))
                    .cornerRadius(6)
                }
            }

            if calendarSyncService.isOrderSynced(order.id) {
                // alarms and location telemetry pills
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                            Text("Alarm: -60m departure")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentBlue.opacity(0.12))
                        .foregroundColor(Color.accentBlue)
                        .cornerRadius(6)

                        HStack(spacing: 4) {
                            Image(systemName: "bell.badge.waveform.fill")
                                .font(.system(size: 10))
                            Text("Alarm: -15m arrival")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.statusAmber.opacity(0.15))
                        .foregroundColor(Color.statusAmber)
                        .cornerRadius(6)
                    }

                    if let fac = order.facility {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                            Text("Geotagged: \(fac.facilityName) (150m boundary)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(calendarSyncService.isOrderSynced(order.id) ? "Scheduled in Native Calendar" : "Sync Dispatch to Calendar")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                    Text("Automates maintenance window booking with site contact details.")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if calendarSyncService.isOrderSynced(order.id) {
                        Button(role: .destructive, action: {
                            Task {
                                do {
                                    try await calendarSyncService.removeWorkOrderFromCalendar(workOrderId: order.id)
                                    calendarSyncToast = "Work order removed from iOS Calendar."
                                } catch {
                                    calendarSyncToast = "Remove failed: \(error.localizedDescription)"
                                }
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    Button(action: {
                        Task {
                            do {
                                _ = try await calendarSyncService.syncWorkOrderToCalendar(order)
                                let haptic = UINotificationFeedbackGenerator()
                                haptic.notificationOccurred(.success)
                                calendarSyncToast = "Work order synchronized with automated alarms."
                            } catch {
                                calendarSyncToast = "Calendar sync failed: \(error.localizedDescription)"
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: calendarSyncService.isOrderSynced(order.id) ? "arrow.triangle.2.circlepath" : "calendar.badge.plus")
                            Text(calendarSyncService.isOrderSynced(order.id) ? "Update" : "Add to Calendar")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.brandNavy)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.surfaceBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("iOS Calendar Integration: \(calendarSyncService.isOrderSynced(order.id) ? "Scheduled" : "Not Scheduled")")
    }


    // helper for spec table rows
    private func specRow(label: String, value: String) -> some View {
      HStack {
          Text(label)
              .font(.appSubheadline)
              .foregroundColor(.secondary)
          Spacer()
          Text(value)
              .font(.appSubheadline)
              .fontWeight(.medium)
              .foregroundColor(.primary)
      }
    }


    // visual indicators for lifecycle stepper
    private func stepIndicator(title: String, isDone: Bool, isActive: Bool) -> some View {
        VStack(spacing: 3) {
            Circle()
                .fill(isDone ? Color.statusGreen : (isActive ? Color.accentBlue : Color.gray.opacity(0.3)))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 9))
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepConnector(isDone: Bool) -> some View {
        Rectangle()
            .fill(isDone ? Color.statusGreen : Color.gray.opacity(0.3))
            .frame(height: 2)
            .padding(.bottom, 12)
    }
}
