//
//  KeychainService.swift
//  Capster
//

import Foundation
import Security

/// Minimal generic-password Keychain wrapper for storing a single string secret per key.
protocol KeychainServing {
    func readString(key: String) -> String?
    func saveString(_ value: String, key: String) throws
    func deleteString(key: String) throws
}

enum KeychainServiceError: LocalizedError {
    case unexpectedData
    case osStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedData:
            return "The Keychain returned data in an unexpected format."
        case .osStatus(let status):
            let message = SecCopyErrorMessageString(status, nil) as String?
            return "Keychain error \(status): \(message ?? "unknown")"
        }
    }
}

/// Generic-password Keychain item, scoped by the app's bundle identifier as the
/// Keychain "service" attribute so items don't collide with other apps.
final class KeychainService: KeychainServing {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.renanfamous.Capster") {
        self.service = service
    }

    func readString(key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveString(_ value: String, key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainServiceError.unexpectedData }

        var attributes = baseQuery(for: key)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        if addStatus == errSecSuccess { return }

        guard addStatus == errSecDuplicateItem else { throw KeychainServiceError.osStatus(addStatus) }

        let updateStatus = SecItemUpdate(
            baseQuery(for: key) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        guard updateStatus == errSecSuccess else { throw KeychainServiceError.osStatus(updateStatus) }
    }

    func deleteString(key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainServiceError.osStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
