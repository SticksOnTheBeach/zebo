import Foundation

/// Ce qu'on demande à une IA : des consignes, la conversation, et éventuellement le format JSON
/// de la réponse.
public struct AIPrompt: Sendable {
    /// Un message de la conversation.
    public struct Message: Equatable, Sendable {
        public enum Role: Sendable {
            case user
            case assistant
        }

        public let role: Role
        public let text: String

        public init(role: Role, text: String) {
            self.role = role
            self.text = text
        }

        public static func user(_ text: String) -> Message { Message(role: .user, text: text) }
        public static func assistant(_ text: String) -> Message { Message(role: .assistant, text: text) }
    }

    /// Une réponse JSON imposée. Gemini veut le schéma au format OpenAPI, les autres en JSON Schema.
    /// Les dictionnaires ne changent jamais : on peut les partager entre tâches.
    public struct Format: @unchecked Sendable {
        let name: String
        let schema: [String: Any]
        let openAPISchema: [String: Any]
    }

    public var instructions: String
    public var messages: [Message]
    /// Sans format, l'IA répond en texte libre.
    var format: Format?
    /// La longueur maximale de la réponse (Claude l'exige).
    var maxTokens: Int
    /// Combien réfléchir avant de répondre : peu pour discuter, davantage pour coder.
    var effort: Effort = .low

    /// L'effort de réflexion demandé (Claude le règle ; les autres IA l'ignorent).
    public enum Effort: String, Sendable {
        case low
        case medium
        case high
    }

    public init(instructions: String, messages: [Message], maxTokens: Int = 4096) {
        self.instructions = instructions
        self.messages = messages
        self.maxTokens = maxTokens
    }

    init(instructions: String, messages: [Message], format: Format?, maxTokens: Int, effort: Effort = .low) {
        self.instructions = instructions
        self.messages = messages
        self.format = format
        self.maxTokens = maxTokens
        self.effort = effort
    }
}
