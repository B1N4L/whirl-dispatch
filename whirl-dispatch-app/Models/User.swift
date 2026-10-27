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

    init(
        id: String,
        email: String,
        fullName: String,
        phone: String? = nil,
        role: UserRole,
        hourlyLaborRate: String? = nil,
        biometricEnrolled: Bool? = nil,
        isActive: Bool? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phone = phone
        self.role = role
        self.hourlyLaborRate = hourlyLaborRate
        self.biometricEnrolled = biometricEnrolled
        self.isActive = isActive
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, email, fullName, phone, role
        case hourlyLaborRate, biometricEnrolled, isActive, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        role = try container.decode(UserRole.self, forKey: .role)

        if let str = try? container.decodeIfPresent(String.self, forKey: .hourlyLaborRate) {
            hourlyLaborRate = str
        } else if let num = try? container.decodeIfPresent(Double.self, forKey: .hourlyLaborRate) {
            hourlyLaborRate = String(format: "%.2f", num)
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .hourlyLaborRate) {
            hourlyLaborRate = "\(intVal).00"
        } else {
            hourlyLaborRate = nil
        }

        biometricEnrolled = try container.decodeIfPresent(Bool.self, forKey: .biometricEnrolled)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(hourlyLaborRate, forKey: .hourlyLaborRate)
        try container.encodeIfPresent(biometricEnrolled, forKey: .biometricEnrolled)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }


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

struct MessageResponse: Codable {
    let message: String
}

struct TechnicianItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let fullName: String
    let email: String
    let phone: String?
    let role: UserRole
    let isAvailable: Bool
    let status: String
    let activeWorkOrderId: String?
    let activeWorkOrderNumber: String?
    let activeWorkOrderTitle: String?
    let facilityName: String?
}

struct TechniciansResponse: Codable {
    let count: Int?
    let technicians: [TechnicianItem]
}
