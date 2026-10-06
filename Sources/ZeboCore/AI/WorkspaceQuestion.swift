import Foundation

/// La question posée à l'IA, quelle qu'elle soit : quels dossiers servent de workspace pour un genre
/// de projet ? Seuls les noms des dossiers et le nombre de fichiers par extension sont envoyés,
/// jamais le contenu des fichiers. La réponse attendue : `{"workspaces": [{"path", "reason"}]}`.
public enum WorkspaceQuestion {
    /// Ce qui peut mal tourner en demandant à une IA.
    public enum Failure: Error, Equatable {
        /// L'API a répondu par une erreur (clé invalide, quota, panne…).
        case http(status: Int, message: String)
        /// L'IA a refusé de répondre.
        case refused
        /// La réponse a été coupée avant la fin.
        case truncated
        /// La réponse n'a pas la forme attendue.
        case invalidResponse
    }

    /// Au-delà, la liste deviendrait inutilement longue : les dossiers sont triés, on garde les premiers.
    static let maxFolders = 300

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

    /// Le schéma JSON de la réponse (JSON Schema, avec `additionalProperties: false` partout).
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

    private struct Answer: Decodable {
        struct Workspace: Decodable {
            let path: String
            let reason: String
        }

        let workspaces: [Workspace]
    }

    /// Lit la réponse JSON de l'IA. Seuls les chemins qu'on lui a donnés comptent, une seule fois chacun.
    static func advice(fromJSON text: String, candidates: [FolderSummary], provider: AIProvider) throws
        -> WorkspaceAdvice
    {
        guard let answer = try? JSONDecoder().decode(Answer.self, from: Data(text.utf8)) else {
            throw Failure.invalidResponse
        }
        let known = Set(candidates.map(\.path))
        var seen = Set<String>()
        let workspaces = answer.workspaces
            .filter { known.contains($0.path) && seen.insert($0.path).inserted }
            .map { WorkspaceSuggestion(path: $0.path, reason: $0.reason) }
        return WorkspaceAdvice(workspaces: workspaces, source: .ai(provider))
    }

    /// Le message d'erreur d'une API (`{"error": {"message": …}}`, format commun à toutes).
    static func errorMessage(in data: Data) -> String {
        struct ErrorBody: Decodable {
            struct Detail: Decodable { let message: String }
            let error: Detail
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message ?? ""
    }

    /// Envoie la requête ; une réponse autre que 200 devient une erreur claire.
    static func send(_ request: URLRequest, with transport: any HTTPTransport) async throws -> Data {
        let (data, response) = try await transport.send(request)
        guard response.statusCode == 200 else {
            throw Failure.http(status: response.statusCode, message: errorMessage(in: data))
        }
        return data
    }

    static func jsonRequest(url: URL, headers: [String: String], body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else { preconditionFailure("Adresse d'API invalide : \(string)") }
        return url
    }
}
