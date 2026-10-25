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


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

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
                    }
                }
                .padding(.horizontal, 16)


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
