import Foundation
import Security
import ZeboCore

/// Les clés d'API des IA, rangées dans le trousseau de macOS (jamais dans les préférences).
struct KeychainAPIKeyStore: APIKeyStore {
    struct Failure: Error {
        let status: OSStatus
    }

    private static let service = "com.sticksonthebeach.zebo.anthropic"

    /// Une entrée par IA ; Claude garde le nom de la première version, pour ne pas perdre sa clé.
    private static func account(for provider: AIProvider) -> String {
        provider == .claude ? "api-key" : "api-key-\(provider.rawValue)"
    }

    private func query(for provider: AIProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account(for: provider),
        ]
    }

    func readKey(for provider: AIProvider) -> String? {
        var request = query(for: provider)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveKey(_ key: String, for provider: AIProvider) throws {
        deleteKey(for: provider)
        var item = query(for: provider)
        item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw Failure(status: status) }
    }

    func deleteKey(for provider: AIProvider) {
        SecItemDelete(query(for: provider) as CFDictionary)
    }
}
