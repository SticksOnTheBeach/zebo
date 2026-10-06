import Foundation
import Testing

@testable import ZeboCore

/// Une IA qui garde les questions reçues et répond ce qu'on lui dit de répondre.
private final class FakeAI: AIClient, @unchecked Sendable {
    let provider: AIProvider
    let reply: Result<String, AIFailure>
    private(set) var prompts: [AIPrompt] = []

    init(provider: AIProvider = .claude, reply: Result<String, AIFailure> = .success("  Coucou !\n")) {
        self.provider = provider
        self.reply = reply
    }

    func answer(_ prompt: AIPrompt) async throws -> String {
        prompts.append(prompt)
        return try reply.get()
    }
}

@MainActor
@Suite("Discussion avec Zebo")
struct ZeboChatTests {
    @Test("Sans IA, ou sans question, rien ne part")
    func needsAnAIAndAQuestion() {
        let chat = ZeboChat()
        chat.draft = "Salut"
        #expect(!chat.canSend)
        chat.client = FakeAI()
        chat.draft = "   \n"
        #expect(!chat.canSend)
        chat.send()
        #expect(chat.messages.isEmpty)
    }

    @Test("La question part, et la réponse de l'IA s'ajoute, sans espaces autour")
    func sendsAndReceives() async {
        let ai = FakeAI()
        let chat = ZeboChat()
        chat.client = ai
        chat.userName = "Maël"
        chat.draft = " Salut Zebo "
        chat.send()
        #expect(chat.draft.isEmpty)
        #expect(chat.isWaiting)
        #expect(await waitUntil { !chat.isWaiting })
        #expect(chat.messages.map(\.text) == ["Salut Zebo", "Coucou !"])
        #expect(chat.messages.map(\.isFromZebo) == [false, true])
        #expect(ai.prompts.first?.messages == [.user("Salut Zebo")])
        #expect(ai.prompts.first?.instructions.contains("Maël") == true)
    }

    @Test("Une erreur devient une phrase de Zebo, et la question suivante reprend la précédente")
    func failureIsExplainedThenMerged() async {
        let chat = ZeboChat()
        chat.client = FakeAI(provider: .gemini, reply: .failure(.http(status: 401, message: "")))
        chat.draft = "Un"
        chat.send()
        #expect(await waitUntil { !chat.isWaiting })
        #expect(chat.failure == "Gemini refuse ma clé. Vérifie-la dans les Paramètres.")

        chat.draft = "Deux"
        #expect(chat.conversation == [.user("Un")])
        chat.send()
        #expect(chat.failure == nil)
        #expect(await waitUntil { !chat.isWaiting })
    }

    @Test("Les questions sans réponse sont jointes, et la discussion commence par une question")
    func conversationAlternates() async {
        let chat = ZeboChat()
        chat.client = FakeAI()
        for question in ["A", "B"] {
            chat.draft = question
            chat.send()
            #expect(await waitUntil { !chat.isWaiting })
        }
        #expect(chat.conversation == [.user("A"), .assistant("Coucou !"), .user("B"), .assistant("Coucou !")])
    }

    @Test("Changer d'IA recommence la discussion ; changer de modèle, non")
    func switchingAIResets() async {
        let chat = ZeboChat()
        chat.client = FakeAI(provider: .claude)
        chat.draft = "Salut"
        chat.send()
        #expect(await waitUntil { !chat.isWaiting })
        chat.client = FakeAI(provider: .claude)
        #expect(chat.messages.count == 2)
        chat.client = FakeAI(provider: .mistral)
        #expect(chat.messages.isEmpty)
    }

    @Test("Chaque erreur a sa phrase")
    func explanations() {
        #expect(ZeboChat.explain(AIFailure.http(status: 429, message: ""), provider: .openAI).contains("ralentir"))
        #expect(ZeboChat.explain(AIFailure.refused, provider: .claude) == "Je préfère ne pas répondre à ça.")
        #expect(ZeboChat.explain(URLError(.notConnectedToInternet), provider: .mistral).contains("Internet"))
    }
}
