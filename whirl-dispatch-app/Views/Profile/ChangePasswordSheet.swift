//
//  ChangePasswordSheet.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-28.
//

import SwiftUI

struct ChangePasswordSheet: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var localError: String? = nil
    @State private var showSuccessAlert: Bool = false

    private var isFormValid: Bool {
        !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                if let error = localError ?? authVM.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.statusRed)
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.statusRed)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Current Credentials") {
                    SecureField("Current Account Password", text: $currentPassword)
                        .textContentType(.password)
                }

                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("New Credentials")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: newPassword.count >= 6 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(newPassword.count >= 6 ? Color.statusGreen : .secondary)
                                .font(.caption)
                            Text("Minimum 6 characters long")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: (!newPassword.isEmpty && newPassword == confirmPassword) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor((!newPassword.isEmpty && newPassword == confirmPassword) ? Color.statusGreen : .secondary)
                                .font(.caption)
                            Text("Passwords match")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }

                Section {
                    Button(action: performChangePassword) {
                        HStack {
                            Spacer()
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 6)
                            }
                            Text("Update Password")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || authVM.isLoading)
                    .listRowBackground(
                        isFormValid && !authVM.isLoading ? Color.brandNavy : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Password Updated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(authVM.successMessage ?? "Your account password has been updated successfully.")
            }
        }
    }

    private func performChangePassword() {
        localError = nil
        guard newPassword == confirmPassword else {
            localError = "New password and confirmation do not match."
            return
        }

        guard newPassword.count >= 6 else {
            localError = "New password must be at least 6 characters long."
            return
        }

        Task {
            let success = await authVM.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            if success {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                showSuccessAlert = true
            }
        }
    }
}
