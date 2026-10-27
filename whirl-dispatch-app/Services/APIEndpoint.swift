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
    case getExpensesByWorkOrder(workOrderId: String)
    case submitExpense(workOrderId: String, vendorName: String, receiptNumber: String?, currency: String, receiptImageUrl: String, lat: Double, lng: Double, items: [[String: Any]])
    case approveExpense(id: String, status: String, reason: String?)
    case generateEstimate(workOrderId: String)
    case getInvoice(id: String)
    case updateInvoiceStatus(id: String, status: String)
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
        case .getExpensesByWorkOrder(let workOrderId): return "/expenses/work-order/\(workOrderId)"
        case .submitExpense: return "/expenses"
        case .approveExpense(let id, _, _): return "/expenses/\(id)/review"
        case .generateEstimate(let workOrderId): return "/billing/estimate/\(workOrderId)"
        case .getInvoice(let id): return "/billing/invoices/\(id)"
        case .updateInvoiceStatus(let id, _): return "/billing/invoices/\(id)/status"
        case .getBillingInvoices: return "/billing"
        case .getDossier(let workOrderId): return "/dossiers/work-order/\(workOrderId)"
        case .saveDossier: return "/dossiers"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .health, .getFacilities, .getFleet, .getWorkOrders, .getWorkOrderDetail, .getExpenses, .getExpensesByWorkOrder, .getBillingInvoices, .getInvoice, .getDossier, .getAttendanceHistory:
            return .get
        case .login, .clockIn, .clockOut, .pauseBreak, .submitExpense, .generateEstimate, .saveDossier:
            return .post
        case .updateWorkOrderStatus, .approveExpense, .updateInvoiceStatus:
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

      case .submitExpense(let workOrderId, let vendorName, let receiptNumber, let currency, let receiptImageUrl, let lat, let lng, let items):
          var body: [String: Any] = [
              "workOrderId": workOrderId,
              "vendorName": vendorName,
              "currency": currency,
              "receiptImageUrl": receiptImageUrl,
              "receiptStoreLatitude": lat,
              "receiptStoreLongitude": lng,
              "items": items
          ]
          if let receiptNumber = receiptNumber, !receiptNumber.isEmpty {
              body["receiptNumber"] = receiptNumber
          }
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .approveExpense(_, let status, let reason):
          var body: [String: Any] = ["approvalStatus": status]
          if let reason = reason, !reason.isEmpty {
              body["rejectionReason"] = reason
          }
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .updateInvoiceStatus(_, let status):
          let body = ["status": status]
          request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      case .saveDossier(_, let payload):
          request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

      default:
          break
      }

      return request
    }
}
