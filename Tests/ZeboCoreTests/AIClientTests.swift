import Foundation
import Testing

@testable import ZeboCore

/// Répond toujours la même chose et garde la dernière requête reçue.
private final class FakeTransport: HTTPTransport, @unchecked Sendable {
    let status: Int
    let body: String
    private(set) var lastRequest: URLRequest?

    init(status: Int = 200, body: String) {
        self.status = status
        self.body = body
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }

    /// Le corps JSON de la dernière requête.
    func lastBody() throws -> [String: Any] {
        let data = try #require(lastRequest?.httpBody)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private struct FixedKeyStore: APIKeyStore {
    let keys: [AIProvider: String]
    func readKey(for provider: AIProvider) -> String? { keys[provider] }
    func saveKey(_ key: String, for provider: AIProvider) throws {}
    func deleteKey(for provider: AIProvider) {}
}

private let folders = [
    FolderSummary(path: "/Dev/C++", relativePath: "C++", fileCounts: ["cpp": 9], isGitRepository: false),
    FolderSummary(path: "/Dev/Web", relativePath: "Web", fileCounts: ["html": 3], isGitRepository: false),
]

/// Une chaîne JSON (avec ses guillemets), pour l'insérer dans une réponse d'API.
private func quoted(_ text: String) -> String {
    String(data: try! JSONEncoder().encode(text), encoding: .utf8)!
}

extension AIClient {
    /// Raccourci : la question des workspaces, posée à ce client.
    fileprivate func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async throws
        -> WorkspaceAdvice
    {
        try await AIWorkspaceAdvisor(client: self).adviseWorkspaces(for: kind, among: folders)
    }
}

/// Une petite discussion : une question, une réponse, une autre question.
private let chat = AIPrompt(
    instructions: "Tu es Zebo.", messages: [.user("Salut"), .assistant("Coucou !"), .user("Ça va ?")])

private let cppAnswer = #"{"workspaces":[{"path":"/Dev/C++","reason":"Il range tes projets C++."}]}"#

@Suite("Question commune aux IA")
struct WorkspaceQuestionTests {
    @Test("Seuls les noms des dossiers et le nombre de fichiers partent, jamais leur contenu")
    func promptOnlyListsFolders() throws {
        let prompt = try WorkspaceQuestion.prompt(for: .cpp, among: folders)
        #expect(prompt.contains("C++"))
        #expect(prompt.contains(#""cpp":9"#))
    }

    @Test("Un chemin inventé ou répété est écarté")
    func ignoresUnknownAndRepeatedPaths() throws {
        let answer =
            #"{"workspaces":[{"path":"/Ailleurs","reason":"?"},{"path":"/Dev/Web","reason":"a"},{"path":"/Dev/Web","reason":"b"}]}"#
        let advice = try WorkspaceQuestion.advice(fromJSON: answer, candidates: folders, provider: .gemini)
        #expect(advice.workspaces.map(\.path) == ["/Dev/Web"])
        #expect(advice.source == .ai(.gemini))
    }

    @Test("Une erreur HTTP garde le message de l'API")
    func httpErrorKeepsMessage() async {
        let transport = FakeTransport(status: 401, body: #"{"error":{"message":"invalid api key"}}"#)
        await #expect(throws: AIFailure.http(status: 401, message: "invalid api key")) {
            try await OpenAIClient(apiKey: "k", transport: transport).adviseWorkspaces(
                for: .c, among: folders)
        }
    }
}

@Suite("Claude")
struct ClaudeAdvisorTests {
    private func response(_ answer: String, stopReason: String = "end_turn") -> String {
        #"{"content":[{"type":"thinking","thinking":""},{"type":"text","text":\#(quoted(answer))}],"stop_reason":"\#(stopReason)"}"#
    }

    @Test("Claude Opus 5.5, effort bas, réponse au format JSON et repli en cas de refus")
    func requestShape() async throws {
        let transport = FakeTransport(body: response(#"{"workspaces":[]}"#))
        _ = try await ClaudeClient(apiKey: "sk-test", transport: transport)
            .adviseWorkspaces(for: .cpp, among: folders)
        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "server-side-fallback-2026-07-01")
        let body = try transport.lastBody()
        #expect(body["model"] as? String == "claude-opus-5-5")
        #expect(body["fallbacks"] as? String == "default")
        let config = try #require(body["output_config"] as? [String: Any])
        #expect(config["effort"] as? String == "low")
        #expect((config["format"] as? [String: Any])?["type"] as? String == "json_schema")
    }

    @Test("En discussion : la conversation entière, sans format imposé")
    func chatRequest() async throws {
        let transport = FakeTransport(body: response("Super !"))
        let reply = try await ClaudeClient(apiKey: "k", transport: transport).answer(chat)
        #expect(reply == "Super !")
        let body = try transport.lastBody()
        #expect(body["system"] as? String == "Tu es Zebo.")
        let messages = try #require(body["messages"] as? [[String: String]])
        #expect(messages.map { $0["role"] } == ["user", "assistant", "user"])
        let config = try #require(body["output_config"] as? [String: Any])
        #expect(config["format"] == nil)
    }

    @Test("La réponse est lue dans le bloc de texte")
    func parsesAnswer() async throws {
        let advice = try await ClaudeClient(apiKey: "k", transport: FakeTransport(body: response(cppAnswer)))
            .adviseWorkspaces(for: .cpp, among: folders)
        #expect(advice.workspaces == [WorkspaceSuggestion(path: "/Dev/C++", reason: "Il range tes projets C++.")])
        #expect(advice.source == .ai(.claude))
    }

    @Test("Un refus ou une réponse coupée deviennent des erreurs claires")
    func failures() async {
        await #expect(throws: AIFailure.refused) {
            try await ClaudeClient(
                apiKey: "k", transport: FakeTransport(body: response("", stopReason: "refusal"))
            )
            .adviseWorkspaces(for: .c, among: folders)
        }
        await #expect(throws: AIFailure.truncated) {
            try await ClaudeClient(
                apiKey: "k", transport: FakeTransport(body: response("{", stopReason: "max_tokens"))
            )
            .adviseWorkspaces(for: .c, among: folders)
        }
    }
}

@Suite("ChatGPT")
struct OpenAIAdvisorTests {
    private func response(_ content: String, status: String = "completed") -> String {
        #"{"status":"\#(status)","output":[{"type":"reasoning","summary":[]},{"type":"message","content":[\#(content)]}]}"#
    }

    @Test("Responses API, clé en Bearer, schéma JSON strict")
    func requestShape() async throws {
        let transport = FakeTransport(body: response(#"{"type":"output_text","text":\#(quoted(cppAnswer))}"#))
        let advice = try await OpenAIClient(apiKey: "sk-oa", model: "gpt-test", transport: transport)
            .adviseWorkspaces(for: .cpp, among: folders)
        let request = try #require(transport.lastRequest)
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/responses")
        #expect(request.value(forHTTPHeaderField: "authorization") == "Bearer sk-oa")
        let body = try transport.lastBody()
        #expect(body["model"] as? String == "gpt-test")
        let format = try #require((body["text"] as? [String: Any])?["format"] as? [String: Any])
        #expect(format["type"] as? String == "json_schema")
        #expect(format["strict"] as? Bool == true)
        #expect(advice.workspaces.map(\.path) == ["/Dev/C++"])
        #expect(advice.source == .ai(.openAI))
    }

    @Test("En discussion : la conversation en entrée, sans format imposé")
    func chatRequest() async throws {
        let transport = FakeTransport(body: response(#"{"type":"output_text","text":"Super !"}"#))
        #expect(try await OpenAIClient(apiKey: "k", transport: transport).answer(chat) == "Super !")
        let body = try transport.lastBody()
        #expect(body["instructions"] as? String == "Tu es Zebo.")
        #expect((body["input"] as? [[String: String]])?.count == 3)
        #expect(body["text"] == nil)
    }

    @Test("Un refus ou une réponse incomplète deviennent des erreurs claires")
    func failures() async {
        let refusal = FakeTransport(body: response(#"{"type":"refusal","refusal":"Non."}"#))
        await #expect(throws: AIFailure.refused) {
            try await OpenAIClient(apiKey: "k", transport: refusal).adviseWorkspaces(for: .c, among: folders)
        }
        let incomplete = FakeTransport(body: response(#"{"type":"output_text","text":"{"}"#, status: "incomplete"))
        await #expect(throws: AIFailure.truncated) {
            try await OpenAIClient(apiKey: "k", transport: incomplete).adviseWorkspaces(
                for: .c, among: folders)
        }
    }
}

@Suite("Gemini")
struct GeminiAdvisorTests {
    private func response(_ text: String, finishReason: String = "STOP") -> String {
        #"{"candidates":[{"content":{"parts":[{"text":"…","thought":true},{"text":\#(quoted(text))}]},"finishReason":"\#(finishReason)"}]}"#
    }

    @Test("generateContent du modèle choisi, clé en en-tête, réponse JSON avec schéma")
    func requestShape() async throws {
        let transport = FakeTransport(body: response(cppAnswer))
        let advice = try await GeminiClient(apiKey: "AIza-test", model: "gemini-test", transport: transport)
            .adviseWorkspaces(for: .cpp, among: folders)
        let request = try #require(transport.lastRequest)
        #expect(
            request.url?.absoluteString
                == "https://generativelanguage.googleapis.com/v1beta/models/gemini-test:generateContent")
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "AIza-test")
        let config = try #require(try transport.lastBody()["generationConfig"] as? [String: Any])
        #expect(config["responseMimeType"] as? String == "application/json")
        #expect(advice.workspaces.map(\.path) == ["/Dev/C++"])
        #expect(advice.source == .ai(.gemini))
    }

    @Test("En discussion : les réponses de l'IA sont celles du « model », sans format imposé")
    func chatRequest() async throws {
        let transport = FakeTransport(body: response("Super !"))
        #expect(try await GeminiClient(apiKey: "k", transport: transport).answer(chat) == "Super !")
        let body = try transport.lastBody()
        let contents = try #require(body["contents"] as? [[String: Any]])
        #expect(contents.map { $0["role"] as? String } == ["user", "model", "user"])
        #expect(body["generationConfig"] == nil)
    }

    @Test("Un blocage ou une réponse coupée deviennent des erreurs claires")
    func failures() async {
        await #expect(throws: AIFailure.refused) {
            try await GeminiClient(
                apiKey: "k", transport: FakeTransport(body: response("", finishReason: "SAFETY"))
            )
            .adviseWorkspaces(for: .c, among: folders)
        }
        await #expect(throws: AIFailure.refused) {
            try await GeminiClient(
                apiKey: "k", transport: FakeTransport(body: #"{"promptFeedback":{"blockReason":"SAFETY"}}"#)
            )
            .adviseWorkspaces(for: .c, among: folders)
        }
        await #expect(throws: AIFailure.truncated) {
            try await GeminiClient(
                apiKey: "k", transport: FakeTransport(body: response("{", finishReason: "MAX_TOKENS"))
            )
            .adviseWorkspaces(for: .c, among: folders)
        }
    }
}

@Suite("Mistral")
struct MistralAdvisorTests {
    private func response(_ text: String, finishReason: String = "stop") -> String {
        #"{"choices":[{"message":{"role":"assistant","content":\#(quoted(text))},"finish_reason":"\#(finishReason)"}]}"#
    }

    @Test("Chat completions, clé en Bearer, schéma JSON")
    func requestShape() async throws {
        let transport = FakeTransport(body: response(cppAnswer))
        let advice = try await MistralClient(apiKey: "ms-key", transport: transport)
            .adviseWorkspaces(for: .cpp, among: folders)
        let request = try #require(transport.lastRequest)
        #expect(request.url?.absoluteString == "https://api.mistral.ai/v1/chat/completions")
        #expect(request.value(forHTTPHeaderField: "authorization") == "Bearer ms-key")
        let body = try transport.lastBody()
        #expect(body["model"] as? String == "mistral-small-latest")
        #expect((body["response_format"] as? [String: Any])?["type"] as? String == "json_schema")
        #expect(advice.source == .ai(.mistral))
    }

    @Test("En discussion : les consignes en premier message système, sans format imposé")
    func chatRequest() async throws {
        let transport = FakeTransport(body: response("Super !"))
        #expect(try await MistralClient(apiKey: "k", transport: transport).answer(chat) == "Super !")
        let body = try transport.lastBody()
        let messages = try #require(body["messages"] as? [[String: String]])
        #expect(messages.map { $0["role"] } == ["system", "user", "assistant", "user"])
        #expect(body["response_format"] == nil)
    }

    @Test("Une réponse coupée devient une erreur claire")
    func truncated() async {
        await #expect(throws: AIFailure.truncated) {
            try await MistralClient(
                apiKey: "k", transport: FakeTransport(body: response("{", finishReason: "length"))
            )
            .adviseWorkspaces(for: .c, among: folders)
        }
    }
}

@Suite("Choix de l'IA")
struct SmartWorkspaceAdvisorTests {
    @Test("Sans IA choisie, sans clé, ou si elle ne répond pas, Zebo devine lui-même")
    func fallsBackToLocal() async {
        let noProvider = SmartWorkspaceAdvisor(provider: nil, keyStore: FixedKeyStore(keys: [.claude: "k"]))
        #expect(await noProvider.adviseWorkspaces(for: .cpp, among: folders).source == .local)

        let noKey = SmartWorkspaceAdvisor(
            provider: .gemini, keyStore: FixedKeyStore(keys: [.claude: "k"]), transport: FakeTransport(body: ""))
        #expect(await noKey.adviseWorkspaces(for: .cpp, among: folders).source == .local)

        let failing = SmartWorkspaceAdvisor(
            provider: .claude, keyStore: FixedKeyStore(keys: [.claude: "k"]),
            transport: FakeTransport(status: 500, body: "{}"))
        let advice = await failing.adviseWorkspaces(for: .cpp, among: folders)
        #expect(advice.source == .local)
        #expect(advice.workspaces.map(\.path) == ["/Dev/C++"])
    }

    @Test("Avec une clé pour l'IA choisie, c'est elle qui répond, avec le modèle choisi")
    func usesTheChosenAI() async throws {
        let transport = FakeTransport(
            body: #"{"choices":[{"message":{"content":\#(quoted(cppAnswer))},"finish_reason":"stop"}]}"#)
        let smart = SmartWorkspaceAdvisor(
            provider: .mistral, model: "mistral-large-latest", keyStore: FixedKeyStore(keys: [.mistral: "k"]),
            transport: transport)
        #expect(await smart.adviseWorkspaces(for: .cpp, among: folders).source == .ai(.mistral))
        #expect(try transport.lastBody()["model"] as? String == "mistral-large-latest")
    }
}
