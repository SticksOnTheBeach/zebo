import Foundation

/// La question posée à l'IA, quelle qu'elle soit : quels dossiers servent de workspace pour un genre
/// de projet ? Seuls les noms des dossiers et le nombre de fichiers par extension sont envoyés,
/// jamais le contenu des fichiers. La réponse attendue : `{"workspaces": [{"path", "reason"}]}`.
public enum WorkspaceQuestion {
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

    /// La réponse attendue, au format JSON imposé.
    static var format: AIPrompt.Format {
        AIPrompt.Format(name: "workspaces", schema: schema, openAPISchema: openAPISchema)
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

    /// Le même schéma, au format OpenAPI (pour Gemini).
    static var openAPISchema: [String: Any] {
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
            throw AIFailure.invalidResponse
        }
        let known = Set(candidates.map(\.path))
        var seen = Set<String>()
        let workspaces = answer.workspaces
            .filter { known.contains($0.path) && seen.insert($0.path).inserted }
            .map { WorkspaceSuggestion(path: $0.path, reason: $0.reason) }
        return WorkspaceAdvice(workspaces: workspaces, source: .ai(provider))
    }
}
