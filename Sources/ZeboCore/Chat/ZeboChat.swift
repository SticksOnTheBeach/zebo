import Foundation
import Observation

/// Une discussion avec Zebo, dans l'onglet IA de la notch : c'est l'IA choisie qui répond pour lui.
@MainActor
@Observable
public final class ZeboChat {
    /// Une bulle de la discussion.
    public struct Message: Identifiable, Equatable, Sendable {
        public let id = UUID()
        public let isFromZebo: Bool
        public let text: String
    }

    public private(set) var messages: [Message] = []
    /// La question en cours d'écriture.
    public var draft = ""
    /// Une question est partie, la réponse n'est pas encore là.
    public private(set) var isWaiting = false
    /// Ce qui a empêché la dernière réponse, dit simplement.
    public private(set) var failure: String?
    /// Le prénom de l'utilisateur, pour que Zebo l'appelle par son nom.
    public var userName = ""

    /// L'IA qui répond ; `nil` sans IA choisie ou sans clé. Changer d'IA recommence la discussion.
    public var client: (any AIClient)? {
        didSet {
            if client?.provider != oldValue?.provider { reset() }
        }
    }

    /// Au-delà, les plus anciens messages ne sont plus envoyés : la discussion reste légère.
    static let maxContext = 20

    private var pending: Task<Void, Never>?

    public init() {}

    public var provider: AIProvider? { client?.provider }

    private var question: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    public var canSend: Bool { client != nil && !isWaiting && !question.isEmpty }

    /// Envoie la question écrite ; la réponse s'ajoute à la discussion quand elle arrive.
    public func send() {
        guard let client, canSend else { return }
        messages.append(Message(isFromZebo: false, text: question))
        draft = ""
        failure = nil
        isWaiting = true
        let prompt = AIPrompt(instructions: instructions, messages: conversation)
        pending = Task {
            let result: Result<String, any Error>
            do {
                result = .success(try await client.answer(prompt))
            } catch {
                result = .failure(error)
            }
            // Recommencée entre-temps : cette réponse n'a plus sa place.
            guard !Task.isCancelled else { return }
            switch result {
            case .success(let reply):
                messages.append(
                    Message(isFromZebo: true, text: reply.trimmingCharacters(in: .whitespacesAndNewlines)))
            case .failure(let error):
                failure = Self.explain(error, provider: client.provider)
            }
            isWaiting = false
        }
    }

    /// Recommence une discussion vide.
    public func reset() {
        pending?.cancel()
        pending = nil
        messages = []
        failure = nil
        isWaiting = false
    }

    var instructions: String {
        let user = userName.isEmpty ? "son utilisateur" : userName
        return """
            Tu es Zebo, un petit nuage rose qui vit dans la notch du Mac de \(user) et l'aide dans ses \
            projets de code. Tu es chaleureux, un peu espiègle, et tu tutoies.
            Réponds en français, très brièvement : deux ou trois phrases au plus, sans Markdown, sans \
            listes ni blocs de code, car ta réponse s'affiche dans un tout petit espace.
            """
    }

    /// Les derniers messages, en commençant par une question, sans deux messages d'affilée du même
    /// côté (une question restée sans réponse est jointe à la suivante).
    var conversation: [AIPrompt.Message] {
        var recent = messages.suffix(Self.maxContext).drop { $0.isFromZebo }
        var merged: [AIPrompt.Message] = []
        while let message = recent.popFirst() {
            let role: AIPrompt.Message.Role = message.isFromZebo ? .assistant : .user
            if let last = merged.last, last.role == role {
                merged[merged.count - 1] = AIPrompt.Message(role: role, text: last.text + "\n\n" + message.text)
            } else {
                merged.append(AIPrompt.Message(role: role, text: message.text))
            }
        }
        return merged
    }

    /// Ce qui s'est mal passé, en une phrase de Zebo.
    static func explain(_ error: any Error, provider: AIProvider) -> String {
        switch error as? AIFailure {
        case .http(let status, _) where status == 401 || status == 403:
            "\(provider.name) refuse ma clé. Vérifie-la dans les Paramètres."
        case .http(429, _):
            "\(provider.name) me demande de ralentir. Réessaie dans un instant."
        case .http(let status, _):
            "\(provider.name) n'a pas pu répondre (erreur \(status))."
        case .refused:
            "Je préfère ne pas répondre à ça."
        case .truncated:
            "Ma réponse était trop longue, je l'ai perdue en route."
        case .invalidResponse:
            "Je n'ai pas compris la réponse de \(provider.name)."
        case nil:
            "Je n'arrive pas à joindre \(provider.name). Es-tu bien connecté à Internet ?"
        }
    }
}
