//
//  NewDispatchSheet.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-27.
//

import SwiftUI

struct NewDispatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SupervisorViewModel

    @State private var selectedFacilityId: String = ""
    @State private var selectedLeadTechId: String = ""
    @State private var selectedCrewTechIds: Set<String> = []
    @State private var selectedVehicleId: String = ""
    @State private var priority: WorkOrderPriority = .medium
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var scheduledStartTime: Date = Date().addingTimeInterval(1800) // 30 mins ahead
    @State private var scheduledEndTime: Date = Date().addingTimeInterval(16200) // 4.5 hours ahead
    @State private var isSubmitting: Bool = false
    @State private var localErrorMessage: String? = nil

    private var selectedFacility: Facility? {
        viewModel.facilities.first(where: { $0.id == selectedFacilityId })
    }

    private var filteredCrewTechnicians: [TechnicianItem] {
        // Exclude the selected lead technician from the crew checklist to prevent duplicate assignment
        viewModel.availableCrewTechnicians.filter { $0.id != selectedLeadTechId }
    }

    private var isValid: Bool {
        !selectedFacilityId.isEmpty &&
        !selectedLeadTechId.isEmpty &&
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 &&
        taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 &&
        scheduledEndTime > scheduledStartTime
    }

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Client Commercial Facility
                Section {
                    if viewModel.facilities.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading client facilities...")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Select Facility", selection: $selectedFacilityId) {
                            Text("Choose Client Facility...").tag("")
                            ForEach(viewModel.facilities) { facility in
                                Text("\(facility.companyName) - \(facility.facilityName)")
                                    .tag(facility.id)
                            }
                        }
                        .pickerStyle(.menu)

                        if let facility = selectedFacility {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(Color.statusRed)
                                    Text(facility.address)
                                        .font(.appCaption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.north.circle.fill")
                                            .foregroundColor(Color.accentBlue)
                                        Text("Radius: \(Int(facility.geofenceRadius))m")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    if let sla = facility.slaResponseHours {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock.badge.checkmark.fill")
                                                .foregroundColor(Color.statusAmber)
                                            Text("SLA: \(sla)h Response")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Client Commercial Site")
                } footer: {
                    Text("Geofence coordinates will be enforced for on-site anti-ghost clocking telemetry.")
                }

                // Section 2: Lead Technician
                Section {
                    if viewModel.availableLeadTechnicians.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.statusAmber)
                                Text("No Available Lead Technicians")
                                    .font(.appSubheadline)
                                    .fontWeight(.semibold)
                            }
                            Text("All qualified lead personnel are actively on-site or en route to other plant rooms.")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Picker("Lead Technician", selection: $selectedLeadTechId) {
                            Text("Select Lead Technician...").tag("")
                            ForEach(viewModel.availableLeadTechnicians) { tech in
                                HStack {
                                    Text(tech.fullName)
                                    if let phone = tech.phone {
                                        Text("(\(phone))")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(tech.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Lead Technician (Single-Select)")
                } footer: {
                    Text("Designated lead technician holds supervisory authority for safety lockouts and dossiers.")
                }

                // Section 3: Field Crew Members (Multi-select)
                Section {
                    if filteredCrewTechnicians.isEmpty {
                        Text("No additional available crew members.")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(filteredCrewTechnicians) { tech in
                            Button {
                                toggleCrewSelection(tech.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tech.fullName)
                                            .font(.appBody)
                                            .foregroundColor(.primary)
                                        Text(tech.phone ?? "Field Technician")
                                            .font(.appCaption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if selectedCrewTechIds.contains(tech.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.brandNavy)
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    HStack {
                        Text("Assigned Crew Technicians")
                        Spacer()
                        if !selectedCrewTechIds.isEmpty {
                            Text("\(selectedCrewTechIds.count) Selected")
                                .font(.caption2)
                                .foregroundColor(Color.brandNavy)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.brandNavy.opacity(0.1)))
                        }
                    }
                } footer: {
                    Text("Multi-select secondary technicians deployed to assist with heavy component rigging.")
                }

                // Section 4: Fleet Vehicle Asset Allocation
                Section {
                    Picker("Vehicle Asset", selection: $selectedVehicleId) {
                        Text("Unassigned / Own Transit").tag("")
                        ForEach(viewModel.availableFleetVehicles) { vehicle in
                            Text("\(vehicle.assetCode) - \(vehicle.name) (\(vehicle.licensePlate))")
                                .tag(vehicle.id)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Allocated Fleet Vehicle")
                } footer: {
                    Text("Allocated vehicle state will transition to 'DEPLOYED' upon dispatch dispatch.")
                }

                // Section 5: Work Order Classification & Details
                Section {
                    Picker("Dispatch Priority", selection: $priority) {
                        ForEach(WorkOrderPriority.allCases, id: \.self) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    TextField("Dispatch Title (min 5 characters)", text: $title)
                        .font(.appBody)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Breakdown & Task Scope")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $taskDescription)
                            .frame(minHeight: 85)
                            .font(.appBody)
                    }
                } header: {
                    Text("Work Order Details")
                }

                // Section 6: Scheduled Execution Window
                Section {
                    DatePicker("Scheduled Arrival", selection: $scheduledStartTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Scheduled Wrap-Up", selection: $scheduledEndTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Service Schedule Window")
                }

                if let err = localErrorMessage {
                    Section {
                        Text(err)
                            .font(.appCaption)
                            .foregroundColor(Color.statusRed)
                    }
                }
            }
            .navigationTitle("Create New Dispatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submitDispatch()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Create & Dispatch")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .onAppear {
                autoSelectDefaults()
            }
        }
    }

    private func toggleCrewSelection(_ id: String) {
        if selectedCrewTechIds.contains(id) {
            selectedCrewTechIds.remove(id)
        } else {
            selectedCrewTechIds.insert(id)
        }
    }

    private func autoSelectDefaults() {
        if selectedFacilityId.isEmpty, let firstFac = viewModel.facilities.first {
            selectedFacilityId = firstFac.id
        }
        if selectedLeadTechId.isEmpty, let firstLead = viewModel.availableLeadTechnicians.first {
            selectedLeadTechId = firstLead.id
        }
        if selectedVehicleId.isEmpty, let firstVehicle = viewModel.availableFleetVehicles.first {
            selectedVehicleId = firstVehicle.id
        }
    }

    private func submitDispatch() {
        guard isValid else { return }
        isSubmitting = true
        localErrorMessage = nil

        Task {
            let success = await viewModel.createDispatch(
                facilityId: selectedFacilityId,
                leadTechId: selectedLeadTechId,
                crewIds: Array(selectedCrewTechIds),
                vehicleId: selectedVehicleId.isEmpty ? nil : selectedVehicleId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                startTime: scheduledStartTime,
                endTime: scheduledEndTime
            )

            isSubmitting = false
            if success {
                dismiss()
            } else {
                localErrorMessage = viewModel.errorMessage ?? "Failed to create work order dispatch."
            }
        }
    }
}
