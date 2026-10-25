//
//  PhotoInspectionSheet.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-25.
//

import SwiftUI

struct PhotoInspectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let photo: CapturedProofPhoto

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // image container
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                        Text(photo.photoType.label)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(photo.photoType == .postServiceAfter ? Color.statusGreen : (photo.photoType == .baselineBefore ? Color.statusAmber : Color.brandNavy))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .padding(10)
                    }

                    // metadata details
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Diagnostic Photo Telemetry", systemImage: "doc.text.magnifyingglass")
                            .font(.appHeadline)
                            .foregroundColor(Color.brandNavy)

                        Divider()

                        HStack {
                            Text("Capture Timestamp:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(photo.capturedTimestamp.formatted(date: .long, time: .standard))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }

                        if let lat = photo.latitude, let lon = photo.longitude {
                            HStack {
                                Text("Plant Room Coordinates:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.4f° N, %.4f° E", lat, lon))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                            }
                        }

                        HStack {
                            Text("JPEG Compression (0.7x):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(photo.formattedCompressionSavings)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.statusGreen)
                        }

                        if let orig = photo.originalByteSize, let comp = photo.compressedByteSize {
                            HStack {
                                Text("Payload Reduction:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(orig / 1024) KB → \(comp / 1024) KB")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)


                    // notes card
                    if let notes = photo.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Technician Observations", systemImage: "pencil.and.list.clipboard")
                                .font(.appHeadline)
                                .foregroundColor(Color.brandNavy)

                            Divider()

                            Text(notes)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Proof Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
