import Foundation

/// Ce qui peut mal tourner en demandant à une IA.
public enum AIFailure: Error, Equatable {
    /// L'API a répondu par une erreur (clé invalide, quota, panne…).
    case http(status: Int, message: String)
    /// L'IA a refusé de répondre.
    case refused
    /// La réponse a été coupée avant la fin.
    case truncated
    /// La réponse n'a pas la forme attendue.
    case invalidResponse
}
