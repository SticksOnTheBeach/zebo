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
        /// Ce que Zebo a fait sur le Mac en répondant, s'il a agi.
        public internal(set) var action: ActionStatus?
        /// Ce qu'il a proposé de faire en plus, de lui-même, et ce qu'il en est advenu.
        public internal(set) var initiative: ActionStatus?
    }

    /// Où en est une action de Zebo, en une phrase.
    public enum ActionStatus: Equatable, Sendable {
        /// Proposée de lui-même : on attend qu'on l'accepte ou la refuse.
        case proposed(String)
        /// La fiche « nouveau projet » attend son nom et son éditeur.
        case waiting(String)
        case running(String)
        case done(String)
        case failed(String)
        /// Refusée, ou annulée.
        case declined(String)
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

    /// Ce que Zebo peut faire sur le Mac ; sans lui, il ne fait que répondre.
    public var actions: (any ZeboActionPerformer)?

    /// Ce qu'il propose de lui-même, à accepter ou refuser.
    public let initiatives: ZeboInitiatives
    /// Les initiatives autorisées une fois pour toutes (dans les paramètres) : faites sans demander.
    public var alwaysAllowed: Set<ZeboPermission> = []

    /// La fiche « nouveau projet » ouverte dans la notch, s'il y en a une.
    public private(set) var projectDraft: ProjectDraft?
    /// Prévient l'app quand la fiche s'ouvre ou se ferme (pour ouvrir la notch sur l'onglet IA).
    @ObservationIgnored public var onProjectDraftChange: ((ProjectDraft?) -> Void)?
    @ObservationIgnored private var projectDraftAnswer: CheckedContinuation<ProjectDraft?, Never>?

    /// Au-delà, les plus anciens messages ne sont plus envoyés : la discussion reste légère.
    static let maxContext = 20

    private var pending: Task<Void, Never>?

    public init(initiatives: ZeboInitiatives) {
        self.initiatives = initiatives
    }

    public convenience init() {
        self.init(initiatives: ZeboInitiatives())
    }

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
        let performer = actions
        let prompt =
            if let performer {
                AIPrompt(
                    instructions: instructions + "\n\n"
                        + ActionQuestion.instructions(editors: performer.editors, projects: performer.projects),
                    messages: conversation, format: ActionQuestion.format, maxTokens: 4096)
            } else {
                AIPrompt(instructions: instructions, messages: conversation)
            }
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
                if let performer, let answer = ActionQuestion.answer(fromJSON: reply) {
                    await answerAndAct(answer, with: performer)
                    return
                }
                messages.append(
                    Message(isFromZebo: true, text: reply.trimmingCharacters(in: .whitespacesAndNewlines)))
            case .failure(let error):
                failure = Self.explain(error, provider: client.provider)
            }
            isWaiting = false
        }
    }

    /// Affiche la phrase de Zebo, fait l'action qu'il a choisie en montrant où il en est,
    /// puis propose son initiative, s'il en a une.
    private func answerAndAct(_ answer: ActionQuestion.Answer, with performer: any ZeboActionPerformer) async {
        let action: ZeboAction?
        var status: ActionStatus?
        do {
            action = try ActionQuestion.resolve(
                answer.action, editors: performer.editors, projects: performer.projects)
            status = action.map { .running($0.progressText) }
        } catch {
            action = nil
            status = .failed(error.message)
        }
        let text = answer.reply.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = Message(
            isFromZebo: true, text: text.isEmpty ? (action?.progressText ?? "…") : text, action: status)
        messages.append(message)
        isWaiting = false

        if let action {
            await run(action, for: message.id, in: \.action, with: performer)
        }
        if let initiative = answer.initiative {
            await propose(initiative, for: message.id, with: performer)
        }
    }

    /// Propose l'initiative ; acceptée, elle est faite comme une action.
    private func propose(
        _ initiative: ActionQuestion.Initiative, for id: Message.ID, with performer: any ZeboActionPerformer
    ) async {
        // Résolue seulement maintenant : un projet que l'action vient de créer est connu.
        guard contains(id),
            let action = try? ActionQuestion.resolve(
                initiative.action, editors: performer.editors, projects: performer.projects)
        else { return }
        // Autorisée une fois pour toutes : pas besoin de demander.
        if alwaysAllowed.contains(action.permission) {
            await run(action, for: id, in: \.initiative, with: performer)
            return
        }
        let text = initiative.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let proposal = text.isEmpty ? action.progressText : text
        update(id, \.initiative, to: .proposed(proposal))
        let isAccepted = await initiatives.ask(proposal)
        guard contains(id) else { return }
        if isAccepted {
            await run(action, for: id, in: \.initiative, with: performer)
        } else {
            update(id, \.initiative, to: .declined(proposal))
        }
    }

    /// Fait une action ; une création de projet passe d'abord par la fiche (nom et éditeur).
    private func run(
        _ action: ZeboAction, for id: Message.ID, in field: WritableKeyPath<Message, ActionStatus?>,
        with performer: any ZeboActionPerformer
    ) async {
        var action = action
        if case .createProject(let name, let kind, let editor) = action {
            update(id, field, to: .waiting("Choisis son nom et son éditeur…"))
            let draft = await askForProject(
                ProjectDraft(kind: kind, name: name, editor: editor, editors: performer.editors))
            guard contains(id) else { return }
            guard let draft else {
                update(id, field, to: .declined("Création annulée."))
                return
            }
            action = .createProject(
                name: ProjectScaffolder.folderName(for: draft.name), kind: kind, editor: draft.editor)
        }
        update(id, field, to: .running(action.progressText))
        let outcome: ActionStatus
        do {
            outcome = .done(try await performer.perform(action))
        } catch let error as ZeboActionError {
            outcome = .failed(error.message)
        } catch {
            outcome = .failed(error.localizedDescription)
        }
        update(id, field, to: outcome)
    }

    /// Le message est toujours là (la discussion n'a pas été recommencée entre-temps).
    private func contains(_ id: Message.ID) -> Bool {
        messages.contains { $0.id == id }
    }

    private func update(_ id: Message.ID, _ field: WritableKeyPath<Message, ActionStatus?>, to status: ActionStatus) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index][keyPath: field] = status
    }

    // MARK: - Fiche « nouveau projet »

    /// Ouvre la fiche et attend qu'on la valide (ou qu'on l'annule : `nil`).
    private func askForProject(_ draft: ProjectDraft) async -> ProjectDraft? {
        // Une seule fiche à la fois : la précédente est annulée.
        finishProjectDraft(with: nil)
        return await withCheckedContinuation { answer in
            projectDraftAnswer = answer
            projectDraft = draft
            onProjectDraftChange?(draft)
        }
    }

    /// « Créer » : le projet part avec le nom et l'éditeur choisis.
    public func confirmProjectDraft() {
        guard let projectDraft, projectDraft.canCreate else { return }
        finishProjectDraft(with: projectDraft)
    }

    public func cancelProjectDraft() {
        finishProjectDraft(with: nil)
    }

    private func finishProjectDraft(with result: ProjectDraft?) {
        guard let answer = projectDraftAnswer else { return }
        projectDraftAnswer = nil
        projectDraft = nil
        onProjectDraftChange?(nil)
        answer.resume(returning: result)
    }

    /// Recommence une discussion vide.
    public func reset() {
        pending?.cancel()
        pending = nil
        messages = []
        failure = nil
        isWaiting = false
        cancelProjectDraft()
        initiatives.dismissAll()
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
            let text = Self.remembered(message)
            if let last = merged.last, last.role == role {
                merged[merged.count - 1] = AIPrompt.Message(role: role, text: last.text + "\n\n" + text)
            } else {
                merged.append(AIPrompt.Message(role: role, text: text))
            }
        }
        return merged
    }

    /// Un message tel que l'IA s'en souvient : avec ce que Zebo a fait (ou n'a pas pu faire),
    /// et ce qu'est devenue son initiative.
    private static func remembered(_ message: Message) -> String {
        let notes = [note(on: message.action), note(on: message.initiative).map { "Initiative — " + $0 }]
        return ([message.text] + notes.compactMap { $0.map { "(\($0))" } }).joined(separator: "\n")
    }

    private static func note(on status: ActionStatus?) -> String? {
        switch status {
        case .done(let text): "Fait : \(text)"
        case .failed(let text): "Échec : \(text)"
        case .declined(let text): "Refusé : \(text)"
        case .proposed(let text): "Proposé, sans réponse : \(text)"
        case .waiting, .running, nil: nil
        }
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
