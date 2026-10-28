//
//  APIService.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-08.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case notFound(message: String? = nil)
    case decodingError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API server URL."
        case .networkError(let err):
            return "Network connection failed: \(err.localizedDescription)"
        case .serverError(let code, let msg):
            return "Server responded with code \(code): \(msg)"
        case .unauthorized:
            return "Session expired or invalid credentials. Please log in again."
        case .notFound(let msg):
            return msg ?? "The requested record was not found on the server."
        case .decodingError(let err):
            return "Data parsing error: \(err.localizedDescription)"
        case .unknownError:
            return "An unexpected error occurred while communicating with the server."
        }
    }
}


final class APIService {
    static let shared = APIService()

    private let session: URLSession
    var authToken: String? = nil

    init(session: URLSession = .shared) {
        self.session = session
    }


    // generic request returning decoded json object
    func send<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let request = try endpoint.makeRequest(token: authToken)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknownError
        }

        // handle error status codes
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode == 404 {
            var notFoundMsg: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                notFoundMsg = json["message"] as? String ?? json["error"] as? String
            }
            throw APIError.notFound(message: notFoundMsg)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // try to parse error message if returned
            var serverMessage = "Request failed"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["error"] as? String ?? json["message"] as? String {
                serverMessage = msg
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: serverMessage)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }


    // quick ping to verify backend is up
    func checkHealth() async -> Bool {
        do {
            let request = try APIEndpoint.health.makeRequest()
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return true
            }
            return false
        } catch {
            return false
        }
    }
}
