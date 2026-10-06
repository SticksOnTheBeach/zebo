import Foundation

/// Une IA à qui l'on pose une question (Claude, ChatGPT, Gemini, Mistral) : elle répond par un texte,
/// libre ou au format JSON demandé. Repérer les workspaces et discuter avec Zebo passent par elle.
public protocol AIClient: Sendable {
    var provider: AIProvider { get }
    func answer(_ prompt: AIPrompt) async throws -> String
}
