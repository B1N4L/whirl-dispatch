//
//  LoginView.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-11.
//

import SwiftUI

@MainActor
struct LoginView: View {
    @State var viewModel: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init() {
        self.init(viewModel: AuthViewModel())
    }


    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // brand logo header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.brandNavy)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.brandNavy.opacity(0.3), radius: 8, x: 0, y: 4)

                                Image(systemName: "fanblades.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 24)

                            VStack(spacing: 4) {
                                Text("WHIRL DISPATCH")
                                    .font(.appTitle)
                                    .foregroundColor(.brandNavy)
                                    .tracking(1.5)

                                Text("Commercial HVAC Operations")
                                    .font(.appSubheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 8)


                        // error notification banner if login fails
                        if let errorMsg = viewModel.errorMessage {
                            ErrorBanner(message: errorMsg) {
                                withAnimation {
                                    viewModel.errorMessage = nil
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }


                        // credentials card
                        VStack(spacing: 18) {
                            // email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.appSubheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color.accentBlue)
                                        .frame(width: 20)

                                    TextField("nuwan.tech@whirldispatch.com", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .password
                                        }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(focusedField == .email ? Color.accentBlue : Color.clear, lineWidth: 1.5)
                                )
                            }


                            // password field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.appSubheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color.accentBlue)
                                        .frame(width: 20)

                                    if isPasswordVisible {
                                        TextField("Enter password", text: $password)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.go)
                                            .onSubmit {
                                                performPasswordLogin()
                                            }
                                    } else {
                                        SecureField("Enter password", text: $password)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.go)
                                            .onSubmit {
                                                performPasswordLogin()
                                            }
                                    }

                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24, height: 24)
                                    }
                                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(focusedField == .password ? Color.accentBlue : Color.clear, lineWidth: 1.5)
                                )
                            }


                            // sign in action button
                            PrimaryButton(
                                title: "Sign In",
                                icon: "arrow.right.circle.fill",
                                isLoading: viewModel.isLoading,
                                isEnabled: !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
                            ) {
                                performPasswordLogin()
                            }
                            .padding(.top, 4)


                            // biometric unlock button
                            if viewModel.isBiometricAvailable {
                                Button(action: {
                                    performBiometricLogin()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: viewModel.biometricType.iconName)
                                            .font(.system(size: 20))
                                        Text("Unlock with \(viewModel.biometricType.title)")
                                            .font(.appHeadline)
                                    }
                                    .foregroundColor(Color.brandNavy)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.brandNavy.opacity(0.3), lineWidth: 1.2)
                                    )
                                }
                                .accessibilityLabel("Unlock with biometrics")
                            }

                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.cardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)


                        // quick demo role selector for development testing
                        VStack(spacing: 10) {
                            Text("Demo Quick Access")
                                .font(.appCaption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                roleChip(title: "Tech", email: "nuwan.tech@whirldispatch.com")
                                roleChip(title: "Lead", email: "kasun.lead@whirldispatch.com")
                                roleChip(title: "Supervisor", email: "sarath.supervisor@whirldispatch.com")
                                roleChip(title: "Clerk", email: "anusha.clerk@whirldispatch.com")
                            }

                            if !email.isEmpty {
                                Text("Testing: \(email)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // prefill saved email if available
                if email.isEmpty && !viewModel.savedEmail.isEmpty {
                    email = viewModel.savedEmail
                }
            }
        }
    }


    // execute password authentication
    private func performPasswordLogin() {
        focusedField = nil
        Task {
            _ = await viewModel.login(email: email, password: password)
        }
    }

    // execute biometric sensor authentication
    private func performBiometricLogin() {
        focusedField = nil
        Task {
            _ = await viewModel.loginWithBiometrics()
        }
    }


    // helper chip for quick testing roles
    @ViewBuilder
    private func roleChip(title: String, email: String) -> some View {
      let isSelected = self.email == email
      Button(action: {
          self.email = email
          self.password = "password123"
      }) {
          Text(title)
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundColor(isSelected ? .white : Color.brandNavy)
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .background(
                  Capsule()
                      .fill(isSelected ? Color.brandNavy : Color.brandNavy.opacity(0.08))
              )
      }
      .accessibilityLabel("Select \(title) test role: \(email)")
    }
}


#Preview {
    LoginView(viewModel: AuthViewModel())
}
