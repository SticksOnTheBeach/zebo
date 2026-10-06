import Foundation
import Security
import ZeboCore

/// La clé d'API de Claude, rangée dans le trousseau de macOS (jamais dans les préférences).
struct KeychainAPIKeyStore: APIKeyStore {
    struct Failure: Error {
        let status: OSStatus
    }

    private static let service = "com.sticksonthebeach.zebo.anthropic"
    private static let account = "api-key"

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]
    }

    func readKey() -> String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveKey(_ key: String) throws {
        deleteKey()
        var item = query
        item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw Failure(status: status) }
    }

    func deleteKey() {
        SecItemDelete(query as CFDictionary)
    }
}
