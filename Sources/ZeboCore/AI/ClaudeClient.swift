import Foundation

/// Claude, par l'API Messages d'Anthropic.
public struct ClaudeClient: AIClient {
    static let endpoint = AIHTTP.url("https://api.anthropic.com/v1/messages")

    public let provider = AIProvider.claude
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

    public func answer(_ prompt: AIPrompt) async throws -> String {
        try Self.answerText(in: try await AIHTTP.send(try request(for: prompt), with: transport))
    }

    func request(for prompt: AIPrompt) throws -> URLRequest {
        // Zebo pose des questions simples et attend une réponse rapide : peu de réflexion.
        var outputConfig: [String: Any] = ["effort": "low"]
        if let format = prompt.format {
            outputConfig["format"] = ["type": "json_schema", "schema": format.schema]
        }
        return try AIHTTP.jsonRequest(
            url: Self.endpoint,
            headers: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
                // Si Claude décline, l'API relance la requête sur le modèle de secours recommandé.
                "anthropic-beta": "server-side-fallback-2026-07-01",
            ],
            body: [
                "model": model,
                "max_tokens": prompt.maxTokens,
                "fallbacks": "default",
                "system": prompt.instructions,
                "output_config": outputConfig,
                "messages": prompt.messages.map { message in
                    ["role": message.role == .user ? "user" : "assistant", "content": message.text]
                },
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

    /// Le texte de la réponse (les blocs de réflexion le précèdent).
    static func answerText(in data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw AIFailure.invalidResponse
        }
        switch response.stopReason {
        case "refusal": throw AIFailure.refused
        case "max_tokens": throw AIFailure.truncated
        default: break
        }
        let text = response.content.filter { $0.type == "text" }.compactMap(\.text).joined()
        guard !text.isEmpty else { throw AIFailure.invalidResponse }
        return text
    }
}
