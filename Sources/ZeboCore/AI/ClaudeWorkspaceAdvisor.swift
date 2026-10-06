import Foundation

/// Demande à Claude (API d'Anthropic) quels dossiers servent de workspace pour un genre de projet.
public struct ClaudeWorkspaceAdvisor: WorkspaceAdvisor {
    static let endpoint = WorkspaceQuestion.url("https://api.anthropic.com/v1/messages")

    private let apiKey: String
    private let model: String
    private let transport: any HTTPTransport

    public init(
        apiKey: String, model: String = AIProvider.claude.defaultModel,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.transport = transport
    }

    public func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async throws
        -> WorkspaceAdvice
    {
        let candidates = Array(folders.prefix(WorkspaceQuestion.maxFolders))
        let data = try await WorkspaceQuestion.send(try request(for: kind, among: candidates), with: transport)
        return try WorkspaceQuestion.advice(
            fromJSON: try Self.answerText(in: data), candidates: candidates, provider: .claude)
    }

    func request(for kind: ProjectKind, among folders: [FolderSummary]) throws -> URLRequest {
        try WorkspaceQuestion.jsonRequest(
            url: Self.endpoint,
            headers: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
                // Si Claude décline, l'API relance la requête sur le modèle de secours recommandé.
                "anthropic-beta": "server-side-fallback-2026-07-01",
            ],
            body: [
                "model": model,
                "max_tokens": 8192,
                "fallbacks": "default",
                "system": WorkspaceQuestion.instructions,
                "output_config": [
                    // Trier quelques dossiers ne demande pas une longue réflexion.
                    "effort": "low",
                    "format": ["type": "json_schema", "schema": WorkspaceQuestion.schema],
                ],
                "messages": [["role": "user", "content": try WorkspaceQuestion.prompt(for: kind, among: folders)]],
            ])
    }

    private struct Response: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }

        let content: [Block]
        let stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
    }

    /// Le texte JSON de la réponse (les blocs de réflexion le précèdent).
    static func answerText(in data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw WorkspaceQuestion.Failure.invalidResponse
        }
        switch response.stopReason {
        case "refusal": throw WorkspaceQuestion.Failure.refused
        case "max_tokens": throw WorkspaceQuestion.Failure.truncated
        default: break
        }
        guard let text = response.content.first(where: { $0.type == "text" })?.text else {
            throw WorkspaceQuestion.Failure.invalidResponse
        }
        return text
    }
}
