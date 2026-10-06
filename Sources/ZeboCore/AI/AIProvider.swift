import Foundation

/// Les IA que Zebo sait consulter.
public enum AIProvider: String, Codable, CaseIterable, Sendable {
    case claude
    case openAI
    case gemini
    case mistral

    public var name: String {
        switch self {
        case .claude: "Claude"
        case .openAI: "ChatGPT"
        case .gemini: "Gemini"
        case .mistral: "Mistral"
        }
    }

    public var company: String {
        switch self {
        case .claude: "Anthropic"
        case .openAI: "OpenAI"
        case .gemini: "Google"
        case .mistral: "Mistral AI"
        }
    }

    /// Le modèle utilisé si on n'en choisit pas d'autre.
    public var defaultModel: String {
        switch self {
        case .claude: "claude-opus-5-5"
        case .openAI: "gpt-6-luna"
        case .gemini: "gemini-3.8-flash"
        case .mistral: "mistral-small-latest"
        }
    }

    /// Là où l'on crée une clé d'API.
    public var keysPage: URL? {
        switch self {
        case .claude: URL(string: "https://console.anthropic.com/settings/keys")
        case .openAI: URL(string: "https://platform.openai.com/api-keys")
        case .gemini: URL(string: "https://aistudio.google.com/apikey")
        case .mistral: URL(string: "https://console.mistral.ai/api-keys")
        }
    }

    /// À quoi ressemble une clé (pour l'aide du champ de saisie).
    public var keyPlaceholder: String {
        switch self {
        case .claude: "sk-ant-…"
        case .openAI: "sk-…"
        case .gemini: "AIza…"
        case .mistral: "Clé Mistral"
        }
    }

    /// Le client qui parle à cette IA, avec le modèle choisi (ou celui par défaut).
    public func makeClient(apiKey: String, model: String?, transport: any HTTPTransport) -> any AIClient {
        let model = model?.isEmpty == false ? model ?? defaultModel : defaultModel
        return switch self {
        case .claude: ClaudeClient(apiKey: apiKey, model: model, transport: transport)
        case .openAI: OpenAIClient(apiKey: apiKey, model: model, transport: transport)
        case .gemini: GeminiClient(apiKey: apiKey, model: model, transport: transport)
        case .mistral: MistralClient(apiKey: apiKey, model: model, transport: transport)
        }
    }
}
