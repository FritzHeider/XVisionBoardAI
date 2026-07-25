import Foundation
import Security

/// Thin, correct wrapper over the SecItem generic-password APIs.
///
/// Follows the safe add-or-update pattern (update first, add on not-found) rather
/// than delete-then-add, which loses metadata and races. Every write sets an
/// explicit accessibility level — omitting it defaults to WhenUnlocked, which
/// fails background reads.
enum KeychainStore {
    static let defaultService = "ManifestMe"

    /// Data protection for stored PII/tokens: readable after first unlock (so
    /// background work succeeds), device-bound, and never included in backups.
    private static let accessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    @discardableResult
    static func save(_ data: Data, account: String, service: String = defaultService) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = accessible
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        if status != errSecSuccess {
            print("[KeychainStore] save failed for \(account): OSStatus \(status)")
        }
        return status == errSecSuccess
    }

    static func load(account: String, service: String = defaultService) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(account: String, service: String = defaultService) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
