import Foundation

/// Demande à Gemini (API de Google) quels dossiers servent de workspace pour un genre de projet.
public struct GeminiWorkspaceAdvisor: WorkspaceAdvisor {
    private let apiKey: String
    private let model: String
    private let transport: any HTTPTransport

    public init(
        apiKey: String, model: String = AIProvider.gemini.defaultModel,
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
            fromJSON: try Self.answerText(in: data), candidates: candidates, provider: .gemini)
    }

    func request(for kind: ProjectKind, among folders: [FolderSummary]) throws -> URLRequest {
        let model = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
        return try WorkspaceQuestion.jsonRequest(
            url: WorkspaceQuestion.url(
                "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"),
            headers: ["x-goog-api-key": apiKey],
            body: [
                "systemInstruction": ["parts": [["text": WorkspaceQuestion.instructions]]],
                "contents": [
                    ["role": "user", "parts": [["text": try WorkspaceQuestion.prompt(for: kind, among: folders)]]]
                ],
                "generationConfig": ["responseMimeType": "application/json", "responseSchema": Self.schema],
            ])
    }

    /// Le schéma de la réponse, au format OpenAPI qu'attend `responseSchema`.
    static var schema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "workspaces": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": ["path": ["type": "STRING"], "reason": ["type": "STRING"]],
                        "required": ["path", "reason"],
                    ],
                ]
            ],
            "required": ["workspaces"],
        ]
    }

    private struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                    let thought: Bool?
                }

                let parts: [Part]?
            }

            let content: Content?
            let finishReason: String?
        }

        struct Feedback: Decodable { let blockReason: String? }

        let candidates: [Candidate]?
        let promptFeedback: Feedback?
    }

    /// Le texte JSON de la première réponse (sans les éventuelles pensées du modèle).
    static func answerText(in data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw WorkspaceQuestion.Failure.invalidResponse
        }
        if response.promptFeedback?.blockReason != nil { throw WorkspaceQuestion.Failure.refused }
        guard let candidate = response.candidates?.first else { throw WorkspaceQuestion.Failure.invalidResponse }
        switch candidate.finishReason {
        case "SAFETY", "BLOCKLIST", "PROHIBITED_CONTENT", "SPII", "RECITATION": throw WorkspaceQuestion.Failure.refused
        case "MAX_TOKENS": throw WorkspaceQuestion.Failure.truncated
        default: break
        }
        let text = (candidate.content?.parts ?? []).filter { $0.thought != true }.compactMap(\.text).joined()
        guard !text.isEmpty else { throw WorkspaceQuestion.Failure.invalidResponse }
        return text
    }
}
