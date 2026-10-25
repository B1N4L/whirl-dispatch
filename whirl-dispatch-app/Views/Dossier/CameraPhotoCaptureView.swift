//
//  CameraPhotoCaptureView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-25.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct CameraPhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    var onAttach: (CapturedProofPhoto) -> Void

    @State private var selectedPhotoType: PhotoType = .defectEvidence
    @State private var notesText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var pickerItem: PhotosPickerItem? = nil

    @State private var isShowingCamera: Bool = false
    @State private var isCameraUnavailableAlert: Bool = false

    private let locationManager = LocationManager.shared


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // photo type selection picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Evidence Classification")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Picker("Photo Type", selection: $selectedPhotoType) {
                            ForEach(PhotoType.allCases, id: \.self) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)


                    // image capture / preview zone
                    if let img = selectedImage {
                        VStack(spacing: 12) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 260)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.brandNavy.opacity(0.2), lineWidth: 1)
                                )

                            HStack {
                                Button(role: .destructive, action: {
                                    selectedImage = nil
                                    pickerItem = nil
                                }) {
                                    Label("Retake / Remove", systemImage: "trash")
                                        .font(.caption)
                                }

                                Spacer()

                                Text("\(Int(img.size.width)) × \(Int(img.size.height)) px")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    } else {
                        // camera & photo picker trigger buttons
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 42))
                                .foregroundColor(Color.brandNavy)

                            Text("HVAC Machinery Photo Capture")
                                .font(.appHeadline)
                                .foregroundColor(Color.brandNavy)

                            Text("Capture damaged compressor coils, worn contactors, or before/after service proof.")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)

                            HStack(spacing: 14) {
                                Button(action: {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        isShowingCamera = true
                                    } else {
                                        isCameraUnavailableAlert = true
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                        Text("Open Camera")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.brandNavy)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }

                                PhotosPicker(selection: $pickerItem, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                        Text("Photo Library")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }


                    // geotag & timestamp stamp card
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Field Telemetry Watermark", systemImage: "location.north.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.brandNavy)

                        Divider()

                        HStack {
                            Text("GPS Location:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            if let coord = locationManager.currentCoordinate {
                                Text(String(format: "%.4f° N, %.4f° E", coord.latitude, coord.longitude))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                            } else {
                                Text("Facility Plant Room Site")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Capture Time:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(Date().formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)


                    // notes field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Component Observation Notes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        TextField("e.g. Scuffed compressor rotor or charred wiring connector", text: $notesText, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(10)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)


                    // attach confirmation button
                    Button(action: {
                        guard let img = selectedImage else { return }

                        let coords = locationManager.currentCoordinate
                        let proof = CapturedProofPhoto(
                            id: UUID().uuidString,
                            photoType: selectedPhotoType,
                            image: img,
                            capturedTimestamp: Date(),
                            latitude: coords?.latitude,
                            longitude: coords?.longitude,
                            notes: notesText.isEmpty ? nil : notesText
                        )

                        onAttach(proof)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Attach Photo to Dossier")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedImage != nil ? Color.statusGreen : Color.secondary.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedImage == nil)
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Capture Proof Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraPickerRepresentable(selectedImage: $selectedImage)
            }
            .alert("Camera Unavailable", isPresented: $isCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Camera hardware is not available on this device simulator. Please choose an image from the Photo Library.")
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.selectedImage = uiImage
                        }
                    }
                }
            }
        }
    }
}


// UIKit camera picker representable
struct CameraPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerRepresentable

        init(_ parent: CameraPickerRepresentable) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
