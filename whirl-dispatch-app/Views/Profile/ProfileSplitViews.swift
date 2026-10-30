//
//  ProfileSplitViews.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-28.
//

import SwiftUI

enum ProfileSection: String, CaseIterable, Identifiable {
    case personalContact = "Personal & Contact"
    case securityPassword = "Security & Credentials"
    case operationalRole = "Operational & Contract"
    case sessionDevice = "Session & Diagnostics"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .personalContact: return "person.text.rectangle.fill"
        case .securityPassword: return "lock.shield.fill"
        case .operationalRole: return "briefcase.fill"
        case .sessionDevice: return "server.rack"
        }
    }

    var subtitle: String {
        switch self {
        case .personalContact: return "Email address, contact phone, name"
        case .securityPassword: return "Account password and device sensors"
        case .operationalRole: return "Assigned role and billable labor rate"
        case .sessionDevice: return "Local client, gateway, sign out"
        }
    }
}


// MARK: - Column 2: Profile Section Menu View (Middle Column for iPad Split View)

struct ProfileSectionMenuView: View {
    @Bindable var authVM: AuthViewModel
    @Binding var selectedSection: ProfileSection

    var body: some View {
        List {
            // Identity Summary Header Card
            if let user = authVM.currentUser {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brandNavy, Color.accentBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)

                            Text(user.initials)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.fullName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(user.role.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(roleColor(for: user.role))

                            Text(user.email)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Categories
            Section("Settings Navigation") {
                ForEach(ProfileSection.allCases) { section in
                    Button(action: {
                        selectedSection = section
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: section.iconName)
                                .font(.system(size: 16))
                                .foregroundColor(selectedSection == section ? Color.brandNavy : .secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(section.rawValue)
                                    .font(.system(size: 14, weight: selectedSection == section ? .bold : .medium))
                                    .foregroundColor(selectedSection == section ? Color.brandNavy : .primary)

                                Text(section.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if selectedSection == section {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.brandNavy)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile & Settings")
    }

    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .technician: return Color.accentBlue
        case .leadTechnician: return Color.brandNavy
        case .supervisor: return Color.statusAmber
        case .paymentClerk: return Color.statusGreen
        }
    }
}


// MARK: - Column 3: Profile Detail Pane (Right Column for iPad Split View)

struct ProfileDetailPane: View {
    let section: ProfileSection
    @Bindable var authVM: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch section {
                case .personalContact:
                    PersonalContactDetailView(authVM: authVM)
                case .securityPassword:
                    SecurityCredentialsDetailView(authVM: authVM)
                case .operationalRole:
                    OperationalContractDetailView(authVM: authVM)
                case .sessionDevice:
                    SessionDiagnosticsDetailView(authVM: authVM)
                }
            }
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Detail Subviews

struct PersonalContactDetailView: View {
    @Bindable var authVM: AuthViewModel

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showSavedToast: Bool = false

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
        VStack(alignment: .leading, spacing: 18) {
            // Header Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Personal & Contact Details")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandNavy)

                Text("Manage your corporate contact identity used for dispatch communications and facility telemetry.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
            }

            // Alerts
            if let err = authVM.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundColor(Color.statusRed)
                    Text(err)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.statusRed)
                    Spacer()
                }
                .padding(12)
                .background(Color.statusRed.opacity(0.12))
                .cornerRadius(8)
            }

            if showSavedToast, let msg = authVM.successMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.statusGreen)
                    Text(msg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.statusGreen)
                    Spacer()
                }
                .padding(12)
                .background(Color.statusGreen.opacity(0.12))
                .cornerRadius(8)
            }

            // Form Card
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full Name")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    TextField("Full Legal Name", text: $fullName)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Corporate Email Address")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    Text("Used for authentication, notifications, and billing audit logs.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Emergency Contact Phone")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    TextField("Mobile Phone (e.g. +94 77 123 4567)", text: $phone)
                        .keyboardType(.phonePad)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    Text("Direct dial used for urgent dispatch communications.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Action Buttons
            HStack(spacing: 14) {
                Button(action: saveProfile) {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 6)
                        }
                        Text("Save Profile Changes")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(hasChanges && isValid && !authVM.isLoading ? Color.brandNavy : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!hasChanges || !isValid || authVM.isLoading)

                if hasChanges {
                    Button(action: resetFields) {
                        Text("Discard")
                            .fontWeight(.medium)
                            .frame(width: 100)
                            .padding(.vertical, 12)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .foregroundColor(.secondary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            resetFields()
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
}


struct SecurityCredentialsDetailView: View {
    @Bindable var authVM: AuthViewModel

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var localError: String? = nil
    @State private var showSuccessToast: Bool = false

    private var isPasswordValid: Bool {
        !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Security & Credentials")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandNavy)

                Text("Manage your corporate password, session credentials, and biometric hardware sensors.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
            }

            // Status Banners
            if let err = localError ?? authVM.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundColor(Color.statusRed)
                    Text(err)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.statusRed)
                    Spacer()
                }
                .padding(12)
                .background(Color.statusRed.opacity(0.12))
                .cornerRadius(8)
            }

            if showSuccessToast, let msg = authVM.successMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.statusGreen)
                    Text(msg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.statusGreen)
                    Spacer()
                }
                .padding(12)
                .background(Color.statusGreen.opacity(0.12))
                .cornerRadius(8)
            }

            // Change Password Card
            VStack(alignment: .leading, spacing: 14) {
                Label("Change Account Password", systemImage: "key.fill")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Password")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    SecureField("Enter Current Password", text: $currentPassword)
                        .textContentType(.password)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("New Password")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    SecureField("New Password (min 6 characters)", text: $newPassword)
                        .textContentType(.newPassword)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm New Password")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }

                Button(action: performChangePassword) {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 6)
                        }
                        Text("Update Account Password")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPasswordValid && !authVM.isLoading ? Color.brandNavy : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!isPasswordValid || authVM.isLoading)
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Biometrics & Device Sensor Card
            VStack(alignment: .leading, spacing: 14) {
                Label("Hardware Biometrics & Sensor Status", systemImage: "faceid")
                    .font(.appHeadline)
                    .foregroundColor(Color.brandNavy)

                Divider()

                HStack {
                    Label(authVM.biometricType.title, systemImage: authVM.biometricType.iconName)
                        .font(.system(size: 14))
                    Spacer()
                    Text(authVM.isBiometricAvailable ? "Sensor Active" : "Sensor Unavailable")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(authVM.isBiometricAvailable ? Color.statusGreen : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(authVM.isBiometricAvailable ? Color.statusGreen.opacity(0.12) : Color.gray.opacity(0.12))
                        )
                }

                HStack {
                    Label("Key Storage", systemImage: "lock.shield.fill")
                        .font(.system(size: 14))
                    Spacer()
                    Text("iOS Keychain Hardware Enclave")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func performChangePassword() {
        localError = nil
        guard newPassword == confirmPassword else {
            localError = "New password and confirm password do not match."
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
                showSuccessToast = true
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            }
        }
    }
}


struct OperationalContractDetailView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Operational & Contract Parameters")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandNavy)

                Text("System parameters and billing rates derived from your employment contract. These fields are strictly read-only and maintained by dispatch directors.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
            }

            if let user = authVM.currentUser {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Assigned Operational Role")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text(user.role.displayName)
                                .font(.appHeadline)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Contract Hourly Labor Rate")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            if let rate = user.hourlyLaborRate {
                                Text(AppCurrency.formatRate(stringVal: rate))
                                    .font(.appMono)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.brandNavy)
                            } else {
                                Text("N/A (Administrative Role)")
                                    .font(.appBody)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Account Status")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Active Corporate Dispatcher")
                                .font(.appSubheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.statusGreen)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color.statusGreen)
                    }
                    .padding(14)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
}


struct SessionDiagnosticsDetailView: View {
    @Bindable var authVM: AuthViewModel
    @State private var showingSignOutAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Session & Diagnostics")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandNavy)

                Text("Client build telemetry, gateway environment, and active session management.")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Client Application")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("WhirlDispatch HVAC Mobile Client v1.0.0")
                        .font(.system(size: 13, weight: .medium))
                }

                Divider()

                HStack {
                    Text("Backend API Gateway")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Live Vercel Production")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.statusGreen)
                }
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Sign Out Button
            Button(role: .destructive, action: {
                showingSignOutAlert = true
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out of Session")
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.statusRed.opacity(0.12))
                .foregroundColor(Color.statusRed)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.statusRed.opacity(0.3), lineWidth: 1)
                )
            }
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
}
