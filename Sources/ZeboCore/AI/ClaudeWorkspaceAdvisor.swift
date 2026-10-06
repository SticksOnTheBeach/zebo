import Foundation

/// Demande à Claude quels dossiers servent de workspace pour un genre de projet.
/// Seuls les noms des dossiers et le nombre de fichiers par extension sont envoyés,
/// jamais le contenu des fichiers.
public struct ClaudeWorkspaceAdvisor: WorkspaceAdvisor {
    public enum Failure: Error, Equatable {
        /// L'API a répondu par une erreur (clé invalide, quota, panne…).
        case http(status: Int, message: String)
        /// Claude a refusé de répondre.
        case refused
        /// La réponse a été coupée avant la fin.
        case truncated
        /// La réponse n'a pas la forme attendue.
        case invalidResponse
    }

    static let endpoint: URL = {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            preconditionFailure("Adresse de l'API invalide")
        }
        return url
    }()
    static let model = "claude-opus-5-5"
    /// Au-delà, la liste deviendrait inutilement longue : les dossiers sont triés, on garde les premiers.
    static let maxFolders = 300

    private let apiKey: String
    private let transport: any HTTPTransport

    public init(apiKey: String, transport: any HTTPTransport = URLSessionTransport()) {
        self.apiKey = apiKey
        self.transport = transport
    }

    public func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async throws
        -> WorkspaceAdvice
    {
        let candidates = Array(folders.prefix(Self.maxFolders))
        let (data, response) = try await transport.send(try request(for: kind, among: candidates))
        guard response.statusCode == 200 else {
            throw Failure.http(status: response.statusCode, message: Self.errorMessage(in: data))
        }
        return try Self.advice(from: data, candidates: candidates)
    }

    // MARK: - Requête

    func request(for kind: ProjectKind, among folders: [FolderSummary]) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        // Si Claude décline, l'API relance la requête sur le modèle de secours recommandé.
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: body(for: kind, among: folders))
        return request
    }

    func body(for kind: ProjectKind, among folders: [FolderSummary]) throws -> [String: Any] {
        [
            "model": Self.model,
            "max_tokens": 8192,
            "fallbacks": "default",
            "system": Self.instructions,
            "output_config": [
                // Trier quelques dossiers ne demande pas une longue réflexion.
                "effort": "low",
                "format": ["type": "json_schema", "schema": Self.schema],
            ],
            "messages": [["role": "user", "content": try Self.prompt(for: kind, among: folders)]],
        ]
    }

    static let instructions = """
        Tu aides Zebo, un petit assistant macOS, à ranger les projets de code de son utilisateur.
        On te donne les dossiers de son dossier de projets, avec le nombre de fichiers par extension.
        Un workspace est un dossier qui regroupe plusieurs projets d'un même langage ou d'un même thème \
        (par exemple « C++ » qui contient plusieurs projets C++, ou « Web » pour des sites). \
        Un dépôt Git est en général un projet, pas un workspace.
        Renvoie les workspaces qui conviennent au genre de projet demandé, du plus probable au moins \
        probable, chacun avec une raison courte en français (une phrase, sans jargon). \
        S'il n'y en a aucun, renvoie une liste vide. N'utilise que des chemins donnés, sans en inventer.
        """

    static func prompt(for kind: ProjectKind, among folders: [FolderSummary]) throws -> String {
        let extensions = kind.fileExtensions.sorted().joined(separator: ", ")
        let listing = folders.map { folder -> [String: Any] in
            [
                "path": folder.path, "relativePath": folder.relativePath,
                "filesByExtension": folder.fileCounts, "isGitRepository": folder.isGitRepository,
            ]
        }
        let json = try JSONSerialization.data(withJSONObject: listing, options: [.sortedKeys])
        return """
            Genre de projet : \(kind.name) (extensions : \(extensions)).
            Dossiers :
            \(String(decoding: json, as: UTF8.self))
            """
    }

    static var schema: [String: Any] {
        [
            "type": "object",
            "properties": [
                "workspaces": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": ["path": ["type": "string"], "reason": ["type": "string"]],
                        "required": ["path", "reason"],
                        "additionalProperties": false,
                    ],
                ]
            ],
            "required": ["workspaces"],
            "additionalProperties": false,
        ]
    }

    // MARK: - Réponse

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

    private struct Answer: Decodable {
        struct Workspace: Decodable {
            let path: String
            let reason: String
        }

        let workspaces: [Workspace]
    }

    static func advice(from data: Data, candidates: [FolderSummary]) throws -> WorkspaceAdvice {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw Failure.invalidResponse
        }
        switch response.stopReason {
        case "refusal": throw Failure.refused
        case "max_tokens": throw Failure.truncated
        default: break
        }
        // La réponse JSON est dans le bloc de texte (les blocs de réflexion le précèdent).
        guard let text = response.content.first(where: { $0.type == "text" })?.text,
            let answer = try? JSONDecoder().decode(Answer.self, from: Data(text.utf8))
        else { throw Failure.invalidResponse }

        // Seuls les chemins qu'on lui a donnés comptent, une seule fois chacun.
        let known = Set(candidates.map(\.path))
        var seen = Set<String>()
        let workspaces = answer.workspaces
            .filter { known.contains($0.path) && seen.insert($0.path).inserted }
            .map { WorkspaceSuggestion(path: $0.path, reason: $0.reason) }
        return WorkspaceAdvice(workspaces: workspaces, source: .ai)
    }

    static func errorMessage(in data: Data) -> String {
        struct ErrorBody: Decodable {
            struct Detail: Decodable { let message: String }
            let error: Detail
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message ?? ""
    }
}

/// Claude s'il y a une clé d'API, sinon (ou s'il n'a pas pu répondre) la détection locale.
public struct SmartWorkspaceAdvisor: WorkspaceAdvisor {
    private let keyStore: any APIKeyStore
    private let transport: any HTTPTransport
    private let fallback = LocalWorkspaceAdvisor()

    public init(keyStore: any APIKeyStore, transport: any HTTPTransport = URLSessionTransport()) {
        self.keyStore = keyStore
        self.transport = transport
    }

    public func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async -> WorkspaceAdvice {
        if let key = keyStore.readKey(), !key.isEmpty {
            let claude = ClaudeWorkspaceAdvisor(apiKey: key, transport: transport)
            if let advice = try? await claude.adviseWorkspaces(for: kind, among: folders) {
                return advice
            }
        }
        return await fallback.adviseWorkspaces(for: kind, among: folders)
    }
}
