//
//  ProfileTabView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-17.
//

import SwiftUI

struct ProfileTabView: View {
    @Bindable var authVM: AuthViewModel

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showingSignOutAlert = false
    @State private var showingChangePasswordSheet = false
    @State private var showSavedToast = false

    private var hasChanges: Bool {
        guard let user = authVM.currentUser else { return false }
        let currentPhone = user.phone ?? ""
        return fullName.trimmingCharacters(in: .whitespacesAndNewlines) != user.fullName ||
               email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != user.email.lowercased() ||
               phone.trimmingCharacters(in: .whitespacesAndNewlines) != currentPhone
    }

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        List {
            if let user = authVM.currentUser {
                // Section 1: Identity Card
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brandNavy, Color.accentBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)

                            Text(user.initials)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.appTitle)
                                .fontWeight(.bold)

                            HStack(spacing: 6) {
                                rolePill(role: user.role)

                                if user.biometricEnrolled == true {
                                    Image(systemName: "faceid")
                                        .font(.caption)
                                        .foregroundColor(Color.statusGreen)
                                }
                            }

                            Text(user.email)
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Alert feedback if active
                if let err = authVM.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundColor(Color.statusRed)
                            Text(err)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.statusRed)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if showSavedToast, let msg = authVM.successMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.statusGreen)
                            Text(msg)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.statusGreen)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Section 2: Editable Personal & Contact
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full Name")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("Full Name", text: $fullName)
                            .font(.system(size: 15))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Corporate Email")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("Corporate Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 15))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contact Phone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("Phone Number", text: $phone)
                            .keyboardType(.phonePad)
                            .font(.system(size: 15))
                    }

                    if hasChanges {
                        HStack(spacing: 12) {
                            Button(action: saveProfile) {
                                HStack {
                                    Spacer()
                                    if authVM.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 4)
                                    }
                                    Text("Save Changes")
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .disabled(!isValid || authVM.isLoading)
                            .buttonStyle(.borderedProminent)
                            .tint(Color.brandNavy)

                            Button("Discard", action: resetFields)
                                .buttonStyle(.bordered)
                        }
                        .padding(.top, 4)
                    }
                } header: {
                    Text("Personal & Contact Details")
                } footer: {
                    Text("Changes to your corporate email or emergency contact phone will sync across dispatch services.")
                        .font(.caption2)
                }

                // Section 3: Security & Credentials
                Section("Security & Credentials") {
                    Button(action: {
                        showingChangePasswordSheet = true
                    }) {
                        HStack {
                            Label("Change Account Password", systemImage: "key.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Label(authVM.biometricType.title, systemImage: authVM.biometricType.iconName)
                        Spacer()
                        Text(authVM.isBiometricAvailable ? "Supported" : "Unavailable")
                            .foregroundColor(authVM.isBiometricAvailable ? Color.statusGreen : .secondary)
                    }

                    HStack {
                        Label("Saved Credentials", systemImage: "lock.shield.fill")
                        Spacer()
                        Text("iOS Keychain")
                            .foregroundColor(.secondary)
                    }
                }

                // Section 4: Operational Parameters (Locked)
                Section {
                    HStack {
                        Label("Operational Role", systemImage: "person.badge.shield.checkmark.fill")
                        Spacer()
                        Text(user.role.displayName)
                            .foregroundColor(.secondary)
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let rate = user.hourlyLaborRate {
                        HStack {
                            Label("Contract Rate", systemImage: "banknote.fill")
                            Spacer()
                            Text(AppCurrency.formatRate(stringVal: rate))
                                .font(.appMono)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.brandNavy)
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Label("Dispatch Status", systemImage: "checkmark.seal.fill")
                        Spacer()
                        Text("Active")
                            .foregroundColor(Color.statusGreen)
                    }
                } header: {
                    Text("Operational Profile")
                } footer: {
                    Text("Role assignments and billable labor rates are set by organization administrators.")
                        .font(.caption2)
                }

                // Section 5: Device & Session
                Section {
                    HStack {
                        Label("Backend Gateway", systemImage: "server.rack")
                        Spacer()
                        Text("Live Vercel Production")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive, action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out of Session")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(Color.statusRed)
                    }
                } footer: {
                    Text("WhirlDispatch HVAC Mobile Client v1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile & Settings")
        .onAppear {
            resetFields()
        }
        .sheet(isPresented: $showingChangePasswordSheet) {
            ChangePasswordSheet(authVM: authVM)
        }
        .confirmationDialog(
            "Are you sure you want to sign out?",
            isPresented: $showingSignOutAlert,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                authVM.logout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func resetFields() {
        if let user = authVM.currentUser {
            fullName = user.fullName
            email = user.email
            phone = user.phone ?? ""
        }
    }

    private func saveProfile() {
        Task {
            let success = await authVM.updateProfile(
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if success {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                showSavedToast = true
            }
        }
    }

    // Role indicator color mapping
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .technician: return Color.accentBlue
        case .leadTechnician: return Color.brandNavy
        case .supervisor: return Color.statusAmber
        case .paymentClerk: return Color.statusGreen
        }
    }

    // Custom role indicator pill
    private func rolePill(role: UserRole) -> some View {
        let color = roleColor(for: role)

        return Text(role.displayName)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}

#Preview {
    NavigationStack {
        ProfileTabView(authVM: AuthViewModel())
    }
}
