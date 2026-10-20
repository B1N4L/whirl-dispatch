//
//  APIEndpoint.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-08.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIEndpoint {
    // base url can be toggled to localhost if diagnosing locally
    static var baseURL: String = "https://whirl-dispatch-backend-h6ub.vercel.app/api"
    static let localhostURL: String = "http://localhost:3000/api"

    case health
    case login(email: String, password: String)
    case getFacilities
    case getFleet
    case getWorkOrders
    case getWorkOrderDetail(id: String)
    case updateWorkOrderStatus(id: String, status: String)
   case clockIn(workOrderId: String, lat: Double, lng: Double)
   case clockOut(workOrderId: String, lat: Double, lng: Double)
   case pauseBreak(workOrderId: String, lat: Double, lng: Double)
   case getAttendanceHistory(workOrderId: String)
    case getExpenses
    case submitExpense(workOrderId: String, storeName: String, amount: String, lat: Double, lng: Double, invoiceNum: String)
    case approveExpense(id: String, status: String, reason: String?)
    case getBillingInvoices
    case getDossier(workOrderId: String)
    case saveDossier(workOrderId: String, payload: [String: Any])


    var path: String {
        switch self {
        case .health: return "/health"
        case .login: return "/auth/login"
        case .getFacilities: return "/facilities"
        case .getFleet: return "/fleet"
        case .getWorkOrders: return "/work-orders"
        case .getWorkOrderDetail(let id): return "/work-orders/\(id)"
        case .updateWorkOrderStatus(let id, _): return "/work-orders/\(id)/status"
        case .clockIn: return "/attendance/clock-in"
        case .clockOut: return "/attendance/clock-out"
        case .pauseBreak: return "/attendance/boundary-event"
        case .getAttendanceHistory(let workOrderId): return "/attendance/work-order/\(workOrderId)"
        case .getExpenses: return "/expenses"
        case .submitExpense: return "/expenses"
        case .approveExpense(let id, _, _): return "/expenses/\(id)/approve"
        case .getBillingInvoices: return "/billing"
        case .getDossier(let workOrderId): return "/dossiers/\(workOrderId)"
        case .saveDossier(let workOrderId, _): return "/dossiers/\(workOrderId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .health, .getFacilities, .getFleet, .getWorkOrders, .getWorkOrderDetail, .getExpenses, .getBillingInvoices, .getDossier, .getAttendanceHistory:
            return .get
        case .login, .clockIn, .clockOut, .pauseBreak, .submitExpense:
            return .post
        case .updateWorkOrderStatus, .approveExpense, .saveDossier:
            return .patch
        }
    }


    func makeRequest(token: String? = nil) throws -> URLRequest {
      guard let url = URL(string: "\(APIEndpoint.baseURL)\(path)") else {
          throw URLError(.badURL)
      }

      var request = URLRequest(url: url)
      request.httpMethod = method.rawValue
      request.timeoutInterval = 25.0
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue("application/json", forHTTPHeaderField: "Accept")

      // attach jwt bearer token if logged in
      if let token = token, !token.isEmpty {
          request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      }

      // attach request body for post and patch
      switch self {
      case .login(let email, let password):
          let body: [String: String] = ["email": email, "password": password]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .updateWorkOrderStatus(_, let status):
          let body = ["status": status]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .clockIn(let workOrderId, let lat, let lng):
          let body: [String: Any] = [
              "workOrderId": workOrderId,
              "latitude": lat,
              "longitude": lng,
              "accuracyMeters": 5.0,
              "biometricVerified": false
          ]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .clockOut(let workOrderId, let lat, let lng):
          let body: [String: Any] = [
              "workOrderId": workOrderId,
              "latitude": lat,
              "longitude": lng,
              "accuracyMeters": 5.0
          ]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .pauseBreak(let workOrderId, let lat, let lng):
          let body: [String: Any] = [
              "workOrderId": workOrderId,
              "eventType": "BREAK_PAUSED",
              "latitude": lat,
              "longitude": lng,
              "accuracyMeters": 5.0
          ]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .getAttendanceHistory:
          break

      case .submitExpense(let workOrderId, let storeName, let amount, let lat, let lng, let invoiceNum):
          let body: [String: Any] = [
              "workOrderId": workOrderId,
              "supplierName": storeName,
              "totalAmount": amount,
              "invoiceNumber": invoiceNum,
              "receiptStoreLatitude": lat,
              "receiptStoreLongitude": lng
          ]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .approveExpense(_, let status, let reason):
          var body: [String: Any] = ["status": status]
          if let reason = reason { body["rejectionReason"] = reason }
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .saveDossier(_, let payload):
          request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

      default:
          break
      }

      return request
    }
}
