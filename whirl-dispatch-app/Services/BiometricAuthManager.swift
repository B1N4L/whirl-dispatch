//
//  BiometricAuthManager.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-10.
//

import Foundation
import LocalAuthentication

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID

    var title: String {
        switch self {
        case .none: return "Passcode"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }

    var iconName: String {
        switch self {
        case .none: return "lock.fill"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .opticID: return "eye.fill"
        }
    }
}


final class BiometricAuthManager {
    static let shared = BiometricAuthManager()

    private init() {}


    // check if device has biometrics enabled
    func canEvaluateBiometrics() -> Bool {
      let context = LAContext()
      var error: NSError?
      return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // determine type of biometric sensor
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

       switch context.biometryType {
       case .faceID:
           return .faceID
       case .touchID:
           return .touchID
       case .opticID:
           return .opticID
       default:
           return .none
       }
    }


    // authenticate user using face id or touch id
    func authenticate(reason: String = "Log in to your WhirlDispatch field account") async -> (success: Bool, error: String?) {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        var evalError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evalError) else {
            let desc = evalError?.localizedDescription ?? "Biometric authentication not supported on this device"
            return (false, desc)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return (success, nil)
        } catch let err as LAError {
            // translate common cancel / auth errors
            switch err.code {
            case .userCancel, .appCancel:
                return (false, "Authentication was cancelled")
            case .userFallback:
                return (false, "Fallback to password")
            case .biometryNotEnrolled:
                return (false, "Face ID or Touch ID is not enrolled")
            default:
                return (false, err.localizedDescription)
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
