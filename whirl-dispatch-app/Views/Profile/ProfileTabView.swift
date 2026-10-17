//
//  ProfileTabView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-17.
//

import SwiftUI

struct ProfileTabView: View {
    @Bindable var authVM: AuthViewModel
    @State private var showingSignOutAlert = false


    var body: some View {
        List {
            if let user = authVM.currentUser {
                // section 1: technician identity card
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


                // section 2: operational parameters
                Section("Operational Profile") {
                    HStack {
                        Label("Operational Role", systemImage: "person.badge.shield.checkmark.fill")
                        Spacer()
                        Text(user.role.displayName)
                            .foregroundColor(.secondary)
                    }

                    if let phone = user.phone, !phone.isEmpty {
                        HStack {
                            Label("Emergency Phone", systemImage: "phone.fill")
                            Spacer()
                            Text(phone)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let rate = user.hourlyLaborRate {
                        HStack {
                            Label("Contract Rate", systemImage: "dollarsign.circle.fill")
                            Spacer()
                            Text("$\(rate) / hr")
                                .font(.appMono)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.brandNavy)
                        }
                    }
                }


                // section 3: device and security
                Section("Security & Biometrics") {
                    HStack {
                        Label(authVM.biometricType.title, systemImage: authVM.biometricType.iconName)
                        Spacer()
                        Text(authVM.isBiometricAvailable ? "Supported" : "Unavailable")
                            .foregroundColor(authVM.isBiometricAvailable ? Color.statusGreen : .secondary)
                    }

                    HStack {
                        Label("Saved Credentials", systemImage: "key.fill")
                        Spacer()
                        Text("iOS Keychain")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Backend Gateway", systemImage: "server.rack")
                        Spacer()
                        Text("Live Vercel Production")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }


                // section 4: sign out session trigger
                Section {
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
                    VStack(spacing: 4) {
                        Text("WhirlDispatch HVAC Mobile Client v1.0.0")
                            .font(.caption2)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("NIBM / Coventry University Computing Coursework")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile & Settings")
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


    // role indicator color mapping
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .technician: return Color.accentBlue
        case .leadTechnician: return Color.brandNavy
        case .supervisor: return Color.statusAmber
        case .paymentClerk: return Color.statusGreen
        }
    }

    // custom role indicator pill
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
