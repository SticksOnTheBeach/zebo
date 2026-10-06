import Foundation

/// Mistral, par son API chat completions.
public struct MistralClient: AIClient {
    static let endpoint = AIHTTP.url("https://api.mistral.ai/v1/chat/completions")

    public let provider = AIProvider.mistral
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

    public func answer(_ prompt: AIPrompt) async throws -> String {
        try Self.answerText(in: try await AIHTTP.send(try request(for: prompt), with: transport))
    }

    func request(for prompt: AIPrompt) throws -> URLRequest {
        let conversation = prompt.messages.map { message in
            ["role": message.role == .user ? "user" : "assistant", "content": message.text]
        }
        var body: [String: Any] = [
            "model": model,
            "messages": [["role": "system", "content": prompt.instructions]] + conversation,
        ]
        if let format = prompt.format {
            body["response_format"] = [
                "type": "json_schema",
                "json_schema": ["name": format.name, "schema": format.schema, "strict": true],
            ]
        }
        return try AIHTTP.jsonRequest(url: Self.endpoint, headers: ["authorization": "Bearer \(apiKey)"], body: body)
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

    /// Le texte de la première réponse.
    static func answerText(in data: Data) throws -> String {
        guard let choice = (try? JSONDecoder().decode(Response.self, from: data))?.choices.first else {
            throw AIFailure.invalidResponse
        }
        if choice.finishReason == "length" { throw AIFailure.truncated }
        guard let text = choice.message.content, !text.isEmpty else { throw AIFailure.invalidResponse }
        return text
    }
}
