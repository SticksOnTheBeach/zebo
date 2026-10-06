import Foundation
import Testing

@testable import ZeboCore

@Suite("Workspaces repérés par Claude")
struct ClaudeWorkspaceAdvisorTests {
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
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        }
    }

    private struct FixedKeyStore: APIKeyStore {
        let key: String?
        func readKey() -> String? { key }
        func saveKey(_ key: String) throws {}
        func deleteKey() {}
    }

    private let folders = [
        FolderSummary(path: "/Dev/C++", relativePath: "C++", fileCounts: ["cpp": 9], isGitRepository: false),
        FolderSummary(path: "/Dev/Web", relativePath: "Web", fileCounts: ["html": 3], isGitRepository: false),
    ]

    /// Une réponse de l'API dont le bloc de texte contient `answer`.
    private func apiResponse(_ answer: String, stopReason: String = "end_turn") -> String {
        let text = String(data: try! JSONEncoder().encode(answer), encoding: .utf8)!
        return
            #"{"content":[{"type":"thinking","thinking":""},{"type":"text","text":\#(text)}],"stop_reason":"\#(stopReason)"}"#
    }

    @Test("La requête vise Claude Opus 5.5, en effort bas, avec une réponse au format JSON et un repli")
    func requestShape() async throws {
        let transport = FakeTransport(body: apiResponse(#"{"workspaces":[]}"#))
        _ = try await ClaudeWorkspaceAdvisor(apiKey: "sk-test", transport: transport)
            .adviseWorkspaces(for: .cpp, among: folders)

        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "server-side-fallback-2026-07-01")

        let httpBody = try #require(request.httpBody)
        let body = try #require(JSONSerialization.jsonObject(with: httpBody) as? [String: Any])
        #expect(body["model"] as? String == "claude-opus-5-5")
        #expect(body["fallbacks"] as? String == "default")
        let config = try #require(body["output_config"] as? [String: Any])
        #expect(config["effort"] as? String == "low")
        #expect((config["format"] as? [String: Any])?["type"] as? String == "json_schema")
    }

    @Test("Seuls les noms des dossiers et le nombre de fichiers partent, jamais leur contenu")
    func promptOnlyListsFolders() throws {
        let prompt = try ClaudeWorkspaceAdvisor.prompt(for: .cpp, among: folders)
        #expect(prompt.contains("C++"))
        #expect(prompt.contains(#""cpp":9"#))
    }

    @Test("Les workspaces de la réponse sont rendus dans l'ordre, avec leur raison")
    func parsesWorkspaces() async throws {
        let answer = #"{"workspaces":[{"path":"/Dev/C++","reason":"Il range tes projets C++."}]}"#
        let advice = try await ClaudeWorkspaceAdvisor(apiKey: "k", transport: FakeTransport(body: apiResponse(answer)))
            .adviseWorkspaces(for: .cpp, among: folders)
        #expect(
            advice
                == WorkspaceAdvice(
                    workspaces: [WorkspaceSuggestion(path: "/Dev/C++", reason: "Il range tes projets C++.")],
                    source: .ai))
    }

    @Test("Un chemin inventé ou répété est écarté")
    func ignoresUnknownAndRepeatedPaths() async throws {
        let answer =
            #"{"workspaces":[{"path":"/Ailleurs","reason":"?"},{"path":"/Dev/Web","reason":"a"},{"path":"/Dev/Web","reason":"b"}]}"#
        let advice = try await ClaudeWorkspaceAdvisor(apiKey: "k", transport: FakeTransport(body: apiResponse(answer)))
            .adviseWorkspaces(for: .web, among: folders)
        #expect(advice.workspaces.map(\.path) == ["/Dev/Web"])
    }

    @Test("Un refus, une réponse coupée ou une erreur HTTP deviennent des erreurs claires")
    func failures() async {
        let refusal = FakeTransport(body: apiResponse("", stopReason: "refusal"))
        await #expect(throws: ClaudeWorkspaceAdvisor.Failure.refused) {
            try await ClaudeWorkspaceAdvisor(apiKey: "k", transport: refusal).adviseWorkspaces(for: .c, among: folders)
        }
        let truncated = FakeTransport(body: apiResponse("{", stopReason: "max_tokens"))
        await #expect(throws: ClaudeWorkspaceAdvisor.Failure.truncated) {
            try await ClaudeWorkspaceAdvisor(apiKey: "k", transport: truncated).adviseWorkspaces(
                for: .c, among: folders)
        }
        let unauthorized = FakeTransport(status: 401, body: #"{"error":{"message":"invalid x-api-key"}}"#)
        await #expect(throws: ClaudeWorkspaceAdvisor.Failure.http(status: 401, message: "invalid x-api-key")) {
            try await ClaudeWorkspaceAdvisor(apiKey: "k", transport: unauthorized)
                .adviseWorkspaces(for: .c, among: folders)
        }
    }

    @Test("Sans clé, ou si Claude ne répond pas, Zebo devine lui-même")
    func smartAdvisorFallsBack() async {
        let noKey = SmartWorkspaceAdvisor(keyStore: FixedKeyStore(key: nil), transport: FakeTransport(body: ""))
        #expect(await noKey.adviseWorkspaces(for: .cpp, among: folders).source == .local)

        let failing = SmartWorkspaceAdvisor(
            keyStore: FixedKeyStore(key: "k"), transport: FakeTransport(status: 500, body: "{}"))
        let advice = await failing.adviseWorkspaces(for: .cpp, among: folders)
        #expect(advice.source == .local)
        #expect(advice.workspaces.map(\.path) == ["/Dev/C++"])
    }

    @Test("Avec une clé, c'est Claude qui répond")
    func smartAdvisorUsesClaude() async {
        let answer = #"{"workspaces":[{"path":"/Dev/Web","reason":"Tes sites."}]}"#
        let smart = SmartWorkspaceAdvisor(
            keyStore: FixedKeyStore(key: "k"), transport: FakeTransport(body: apiResponse(answer)))
        let advice = await smart.adviseWorkspaces(for: .web, among: folders)
        #expect(advice.source == .ai)
    }
}
