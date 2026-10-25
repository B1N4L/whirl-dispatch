//
//  DiagnosticDossierView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-25.
//

import SwiftUI

struct DiagnosticDossierView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DossierViewModel
    @State private var isShowingPhotoCapture: Bool = false
    @State private var selectedInspectionPhoto: CapturedProofPhoto? = nil


    init(workOrder: WorkOrder) {
        _viewModel = State(initialValue: DossierViewModel(workOrder: workOrder))
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // notification banner
                    if let toast = viewModel.successToast {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.statusGreen)
                            Text(toast)
                                .font(.appCaption)
                            Spacer()
                            Button(action: { viewModel.successToast = nil }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.statusGreen.opacity(0.12))
                        .cornerRadius(8)
                    }

                    // 1. equipment specification header card
                    equipmentHeaderCard

                    // 2. operational readings comparison card
                    operationalReadingsCard

                    // 3. before and after proof comparison preview
                    beforeAfterComparisonCard

                    // 4. diagnostic inspection checklist
                    inspectionChecklistSection

                    // 5. photo proofs & evidence
                    photoEvidenceSection

                    // 6. technician diagnostic notes
                    technicianNotesCard

                    // 7. save & sync action button
                    Button(action: {
                        Task {
                            _ = await viewModel.saveDossier()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Save Diagnostic Dossier")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandNavy)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Diagnostic Dossier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadDossier()
            }
            .sheet(isPresented: $isShowingPhotoCapture) {
                CameraPhotoCaptureView { proof in
                    viewModel.attachCapturedPhoto(proof)
                }
            }
            .sheet(item: $selectedInspectionPhoto) { photo in
                PhotoInspectionSheet(photo: photo)
            }
        }
    }


    // MARK: - Subviews

    private var equipmentHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.workOrder.facility?.facilityName ?? "Commercial Plant Room")
                        .font(.appCaption)
                        .foregroundColor(.secondary)

                    Text(viewModel.workOrder.workOrderNumber)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandNavy)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "fan.oscillation.fill")
                        .foregroundColor(Color.accentBlue)
                    Text("HVAC Chiller")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentBlue.opacity(0.12))
                .cornerRadius(6)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equipment Model")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Model", text: $viewModel.equipmentModel)
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Serial Number")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Serial", text: $viewModel.equipmentSerialNumber)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


    private var operationalReadingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Operational Pressure & Electrical Metrics", systemImage: "gauge.with.needle.fill")
                .font(.appHeadline)
                .foregroundColor(Color.brandNavy)

            Divider()

            // 3-column table: metric, baseline before, post-service
            VStack(spacing: 8) {
                HStack {
                    Text("Metric")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Before")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.statusAmber)
                        .frame(width: 80, alignment: .trailing)

                    Text("After Service")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.statusGreen)
                        .frame(width: 90, alignment: .trailing)
                }

                Divider()

                metricInputRow(label: "Suction PSI", before: $viewModel.baselineSuctionPsi, after: $viewModel.postSuctionPsi)
                metricInputRow(label: "Discharge PSI", before: $viewModel.baselineDischargePsi, after: $viewModel.postDischargePsi)
                metricInputRow(label: "Motor Running (A)", before: $viewModel.baselineMotorAmps, after: $viewModel.postMotorAmps)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func metricInputRow(label: String, before: Binding<String>, after: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.appSubheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("0.0", text: before)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .frame(width: 75)
                .padding(4)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(6)

            TextField("0.0", text: after)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.statusGreen)
                .frame(width: 85)
                .padding(4)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(6)
        }
    }


    private var beforeAfterComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Before & After Service Proof", systemImage: "arrow.left.and.right.square.fill")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Spacer()

                Text("0.7x JPEG")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.statusGreen.opacity(0.15))
                    .foregroundColor(Color.statusGreen)
                    .cornerRadius(4)
            }

            Divider()

            HStack(spacing: 12) {
                // Before side
                VStack(spacing: 6) {
                    Text("BEFORE SERVICE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.statusAmber)

                    if let before = viewModel.beforeServicePhoto {
                        Button(action: {
                            selectedInspectionPhoto = before
                        }) {
                            Image(uiImage: before.image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 105)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.statusAmber.opacity(0.6), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            .frame(height: 105)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.badge.ellipsis")
                                        .foregroundColor(.secondary)
                                    Text("No Pre-Service Photo")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }

                    Text("Suction: \(viewModel.baselineSuctionPsi) PSI")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Divider arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)

                // After side
                VStack(spacing: 6) {
                    Text("AFTER SERVICE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.statusGreen)

                    if let after = viewModel.afterServicePhoto {
                        Button(action: {
                            selectedInspectionPhoto = after
                        }) {
                            Image(uiImage: after.image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 105)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.statusGreen.opacity(0.6), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            .frame(height: 105)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.badge.ellipsis")
                                        .foregroundColor(.secondary)
                                    Text("No Post-Service Photo")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }

                    Text("Suction: \(viewModel.postSuctionPsi) PSI")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.statusGreen)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


    private var inspectionChecklistSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Machinery Diagnostic Checklist", systemImage: "checklist")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Spacer()

                Text("\(viewModel.completedChecklistCount) / \(viewModel.totalChecklistCount)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.checklistProgress == 1.0 ? Color.statusGreen : Color.brandNavy)
            }

            // progress bar
            ProgressView(value: viewModel.checklistProgress)
                .tint(viewModel.checklistProgress == 1.0 ? Color.statusGreen : Color.brandNavy)

            Divider()

            ForEach(ChecklistCategory.allCases) { cat in
                let items = viewModel.checklistItems.filter { $0.category == cat }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(Color.brandNavy)
                            Text(cat.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.brandNavy)
                        }
                        .padding(.top, 4)

                        ForEach(items) { item in
                            checklistItemRow(item)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func checklistItemRow(_ item: DossierChecklistItem) -> some View {
        Button(action: {
            viewModel.toggleChecklistItem(id: item.id)
        }) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(item.isChecked ? Color.statusGreen : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.itemLabel)
                        .font(.system(size: 13))
                        .foregroundColor(item.isChecked ? .secondary : .primary)
                        .strikethrough(item.isChecked, color: .secondary)

                    if let notes = item.notes {
                        Text(notes)
                            .font(.caption2)
                            .foregroundColor(Color.statusGreen)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 3)
    }


    private var photoEvidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Photo Evidence & Proofs", systemImage: "camera.fill")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Spacer()

                Button(action: {
                    isShowingPhotoCapture = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Proof")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color.brandNavy)
                }
            }

            Divider()

            if viewModel.capturedPhotos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No proof photos attached yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(viewModel.capturedPhotos) { photo in
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedInspectionPhoto = photo
                        }) {
                            Image(uiImage: photo.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 62, height: 62)
                                .cornerRadius(8)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(photo.photoType.label)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(photo.photoType == .postServiceAfter ? Color.statusGreen.opacity(0.15) : (photo.photoType == .baselineBefore ? Color.statusAmber.opacity(0.15) : Color.brandNavy.opacity(0.12)))
                                    .foregroundColor(photo.photoType == .postServiceAfter ? Color.statusGreen : (photo.photoType == .baselineBefore ? Color.statusAmber : Color.brandNavy))
                                    .cornerRadius(4)

                                Spacer()

                                Text(photo.formattedCompressionSavings)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.statusGreen)

                                Button(action: {
                                    viewModel.removeCapturedPhoto(id: photo.id)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if let notes = photo.notes {
                                Text(notes)
                                    .font(.system(size: 12))
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                            }

                            HStack {
                                Text(photo.capturedTimestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                if let lat = photo.latitude, let lon = photo.longitude {
                                    Text("• \(String(format: "%.3f, %.3f", lat, lon))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }


    private var technicianNotesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Technician Diagnostic Summary", systemImage: "note.text")
                .font(.appHeadline)
                .foregroundColor(Color.brandNavy)

            TextField("Enter plant room findings, replaced gaskets, or valve adjustments...", text: $viewModel.diagnosticNotes, axis: .vertical)
                .lineLimit(3...6)
                .padding(10)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
