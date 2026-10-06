import Foundation

/// Demande à Mistral (chat completions) quels dossiers servent de workspace pour un genre de projet.
public struct MistralWorkspaceAdvisor: WorkspaceAdvisor {
    static let endpoint = WorkspaceQuestion.url("https://api.mistral.ai/v1/chat/completions")

    private let apiKey: String
    private let model: String
    private let transport: any HTTPTransport

    public init(
        apiKey: String, model: String = AIProvider.mistral.defaultModel,
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
            fromJSON: try Self.answerText(in: data), candidates: candidates, provider: .mistral)
    }

    func request(for kind: ProjectKind, among folders: [FolderSummary]) throws -> URLRequest {
        try WorkspaceQuestion.jsonRequest(
            url: Self.endpoint,
            headers: ["authorization": "Bearer \(apiKey)"],
            body: [
                "model": model,
                "messages": [
                    ["role": "system", "content": WorkspaceQuestion.instructions],
                    ["role": "user", "content": try WorkspaceQuestion.prompt(for: kind, among: folders)],
                ],
                "response_format": [
                    "type": "json_schema",
                    "json_schema": ["name": "workspaces", "schema": WorkspaceQuestion.schema, "strict": true],
                ],
            ])
    }

    private struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case message
                case finishReason = "finish_reason"
            }
        }

        let choices: [Choice]
    }

    /// Le texte JSON de la première réponse.
    static func answerText(in data: Data) throws -> String {
        guard let choice = (try? JSONDecoder().decode(Response.self, from: data))?.choices.first else {
            throw WorkspaceQuestion.Failure.invalidResponse
        }
        if choice.finishReason == "length" { throw WorkspaceQuestion.Failure.truncated }
        guard let text = choice.message.content else { throw WorkspaceQuestion.Failure.invalidResponse }
        return text
    }
}
