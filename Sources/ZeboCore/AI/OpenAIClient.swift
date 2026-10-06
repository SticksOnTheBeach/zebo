import Foundation

/// ChatGPT, par la Responses API d'OpenAI.
public struct OpenAIClient: AIClient {
    static let endpoint = AIHTTP.url("https://api.openai.com/v1/responses")

    public let provider = AIProvider.openAI
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

    public func answer(_ prompt: AIPrompt) async throws -> String {
        try Self.answerText(in: try await AIHTTP.send(try request(for: prompt), with: transport))
    }

    func request(for prompt: AIPrompt) throws -> URLRequest {
        var body: [String: Any] = [
            "model": model,
            "instructions": prompt.instructions,
            "input": prompt.messages.map { message in
                ["role": message.role == .user ? "user" : "assistant", "content": message.text]
            },
        ]
        if let format = prompt.format {
            body["text"] = [
                "format": ["type": "json_schema", "name": format.name, "schema": format.schema, "strict": true]
            ]
        }
        return try AIHTTP.jsonRequest(url: Self.endpoint, headers: ["authorization": "Bearer \(apiKey)"], body: body)
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

    /// Le texte du message de réponse.
    static func answerText(in data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw AIFailure.invalidResponse
        }
        if response.status == "incomplete" { throw AIFailure.truncated }
        let contents = response.output.filter { $0.type == "message" }.flatMap { $0.content ?? [] }
        if contents.contains(where: { $0.type == "refusal" }) { throw AIFailure.refused }
        let text = contents.filter { $0.type == "output_text" }.compactMap(\.text).joined()
        guard !text.isEmpty else { throw AIFailure.invalidResponse }
        return text
    }
}
