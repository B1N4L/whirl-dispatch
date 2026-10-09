//
//  KeychainManager.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-09.
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

   private let service = "com.whirldispatch.app"
    private let tokenKey = "jwt_access_token"
    private let emailKey = "saved_user_email"

    private init() {}


    // save string value securely into keychain
    @discardableResult
    func save(key: String, value: String) -> Bool {
      guard let data = value.data(using: .utf8) else { return false }

      // remove any previous value first
      delete(key: key)

      let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: service,
          kSecAttrAccount as String: key,
          kSecValueData as String: data,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
      ]

      let status = SecItemAdd(query as CFDictionary, nil)
      return status == errSecSuccess
    }


    // read string value from keychain
    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

       var item: CFTypeRef?
       let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    // delete item from keychain
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

       let status = SecItemDelete(query as CFDictionary)
       return status == errSecSuccess || status == errSecItemNotFound
    }


    // convenience accessors for auth token
    func saveToken(_ token: String) {
        save(key: tokenKey, value: token)
    }

    func getToken() -> String? {
        return read(key: tokenKey)
    }

    func clearToken() {
        delete(key: tokenKey)
    }

    func saveUserEmail(_ email: String) {
       save(key: emailKey, value: email)
    }

    func getUserEmail() -> String? {
        return read(key: emailKey)
    }
}
