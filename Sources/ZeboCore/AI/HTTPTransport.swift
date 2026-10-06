import Foundation

/// Envoie une requête HTTP. Remplaçable dans les tests, pour ne jamais toucher au réseau.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Le vrai réseau, avec `URLSession`.
public struct URLSessionTransport: HTTPTransport {
    public init() {}

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}

/// Garde la clé d'API de Claude (dans le trousseau, pour l'app).
public protocol APIKeyStore: Sendable {
    func readKey() -> String?
    func saveKey(_ key: String) throws
    func deleteKey()
}
