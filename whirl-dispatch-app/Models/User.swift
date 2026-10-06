//
//  User.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-06.
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case technician = "TECHNICIAN"
    case leadTechnician = "LEAD_TECHNICIAN"
    case supervisor = "SUPERVISOR"
    case paymentClerk = "PAYMENT_CLERK"

   var displayName: String {
       switch self {
       case .technician: return "Field Technician"
       case .leadTechnician: return "Lead Technician"
       case .supervisor: return "Operations Supervisor"
       case .paymentClerk: return "Payment Clerk"
       }
   }


  var badgeColorName: String {
      switch self {
      case .technician: return "blue"
      case .leadTechnician: return "purple"
      case .supervisor: return "orange"
      case .paymentClerk: return "green"
      }
  }
}


struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let fullName: String
    let phone: String?
    let role: UserRole
    let hourlyLaborRate: String?
   let biometricEnrolled: Bool?
    let isActive: Bool?
    let createdAt: String?


    // convenient display initials
    var initials: String {
      let parts = fullName.split(separator: " ")
      if parts.count >= 2 {
          return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
      }
      return String(fullName.prefix(2)).uppercased()
    }
}


// login response wrapper from backend
struct AuthResponse: Codable {
    let message: String?
    let token: String
    let user: User
}
