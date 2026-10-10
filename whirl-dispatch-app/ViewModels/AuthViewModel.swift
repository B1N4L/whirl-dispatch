//
//  AuthViewModel.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-10.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class AuthViewModel {
    var currentUser: User? = nil
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    var isBiometricAvailable: Bool = false
    var biometricType: BiometricType = .none
    var savedEmail: String = ""


    private let apiService: APIService
    private let keychain: KeychainManager
    private let biometricManager: BiometricAuthManager
    private let userDefaultsKey = "whirl_cached_user"

    init(
        apiService: APIService? = nil,
        keychain: KeychainManager? = nil,
        biometricManager: BiometricAuthManager? = nil
    ) {
        let api = apiService ?? .shared
        let kc = keychain ?? .shared
        let bio = biometricManager ?? .shared

        self.apiService = api
        self.keychain = kc
        self.biometricManager = bio

        // check device biometric sensor capability
        self.isBiometricAvailable = bio.canEvaluateBiometrics()
        self.biometricType = bio.biometricType
        self.savedEmail = kc.getUserEmail() ?? ""

        // try restoring session if token exists
        restoreSession()
    }


    // authenticate with email and password against backend api
    func login(email: String, password: String) async -> Bool {
      isLoading = true
      errorMessage = nil

      let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
      let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
          errorMessage = "Please enter both email and password."
          isLoading = false
          return false
      }

      do {
          let response: AuthResponse = try await apiService.send(.login(email: trimmedEmail, password: trimmedPassword))

          // store token and user session
          apiService.authToken = response.token
          keychain.saveToken(response.token)
          keychain.saveUserEmail(trimmedEmail)

          if let encoded = try? JSONEncoder().encode(response.user) {
              UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
          }

          currentUser = response.user
          savedEmail = trimmedEmail
          isAuthenticated = true
          isLoading = false
          return true
      } catch let apiErr as APIError {
          isLoading = false
          errorMessage = apiErr.localizedDescription
          return false
      } catch {
          isLoading = false
          errorMessage = error.localizedDescription
          return false
      }
    }


    // unlock session using face id or touch id
    func loginWithBiometrics() async -> Bool {
        guard let token = keychain.getToken(), !token.isEmpty else {
            errorMessage = "No saved session found. Please log in with password first."
            return false
        }

        isLoading = true
        errorMessage = nil

        let result = await biometricManager.authenticate(reason: "Unlock WhirlDispatch using biometrics")

        guard result.success else {
            isLoading = false
            if let err = result.error, err != "Authentication was cancelled" {
                errorMessage = err
            }
            return false
        }

       // restore auth token into api client
       apiService.authToken = token

        // restore cached user info
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        } else {
            // fallback minimal technician if cached data missing
            currentUser = User(
                id: "restored-user",
                email: savedEmail.isEmpty ? "tech@whirldispatch.com" : savedEmail,
                fullName: "Field Technician",
                phone: "+1 (555) 234-5678",
                role: .technician,
                hourlyLaborRate: "95.00",
                biometricEnrolled: true,
                isActive: true,
                createdAt: nil
            )
            isAuthenticated = true
        }

        isLoading = false
        return true
    }


    // clear session and return to login
    func logout() {
      apiService.authToken = nil
      keychain.clearToken()
      UserDefaults.standard.removeObject(forKey: userDefaultsKey)
      currentUser = nil
      isAuthenticated = false
      errorMessage = nil
    }


    // check if valid cached token exists on launch
    func restoreSession() {
        if let token = keychain.getToken(), !token.isEmpty {
            apiService.authToken = token
            if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
               let user = try? JSONDecoder().decode(User.self, from: data) {
                currentUser = user
                isAuthenticated = true
            }
        }
    }
}
