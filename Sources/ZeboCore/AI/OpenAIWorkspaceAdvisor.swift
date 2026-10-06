import Foundation

/// Demande à ChatGPT (Responses API d'OpenAI) quels dossiers servent de workspace pour un genre de projet.
public struct OpenAIWorkspaceAdvisor: WorkspaceAdvisor {
    static let endpoint = WorkspaceQuestion.url("https://api.openai.com/v1/responses")

    private let apiKey: String
    private let model: String
    private let transport: any HTTPTransport

    public init(
        apiKey: String, model: String = AIProvider.openAI.defaultModel,
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
            fromJSON: try Self.answerText(in: data), candidates: candidates, provider: .openAI)
    }

    func request(for kind: ProjectKind, among folders: [FolderSummary]) throws -> URLRequest {
        try WorkspaceQuestion.jsonRequest(
            url: Self.endpoint,
            headers: ["authorization": "Bearer \(apiKey)"],
            body: [
                "model": model,
                "instructions": WorkspaceQuestion.instructions,
                "input": try WorkspaceQuestion.prompt(for: kind, among: folders),
                "text": [
                    "format": [
                        "type": "json_schema", "name": "workspaces", "schema": WorkspaceQuestion.schema, "strict": true,
                    ]
                ],
            ])
    }

    private struct Response: Decodable {
        struct Item: Decodable {
            struct Content: Decodable {
                let type: String
                let text: String?
            }

            let type: String
            let content: [Content]?
        }

        let status: String?
        let output: [Item]
    }

    /// Le texte JSON du message de réponse.
    static func answerText(in data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw WorkspaceQuestion.Failure.invalidResponse
        }
        if response.status == "incomplete" { throw WorkspaceQuestion.Failure.truncated }
        let contents = response.output.filter { $0.type == "message" }.flatMap { $0.content ?? [] }
        if contents.contains(where: { $0.type == "refusal" }) { throw WorkspaceQuestion.Failure.refused }
        guard let text = contents.first(where: { $0.type == "output_text" })?.text else {
            throw WorkspaceQuestion.Failure.invalidResponse
        }
        return text
    }
}
