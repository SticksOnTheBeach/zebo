import Foundation

/// Quand Zebo peut agir, l'IA répond en JSON : sa phrase, et une action à faire (ou « none »).
/// Elle ne connaît que les éditeurs et les projets qu'on lui donne, et ne peut rien inventer d'autre.
enum ActionQuestion {
    /// L'action telle que l'IA la décrit ; les champs inutiles sont vides.
    struct Request: Decodable, Equatable {
        var type: String
        var editor: String
        var project: String
        var kind: String
        var name: String
    }

    struct Answer: Decodable, Equatable {
        var reply: String
        var action: Request
    }

    static let types = ["none", "open_editor", "open_project", "create_project"]

    static func instructions(editors: [IDEChoice], projects: [ZeboProject]) -> String {
        let editorList = editors.isEmpty ? "aucun" : editors.map(\.name).joined(separator: ", ")
        let projectList =
            projects.isEmpty ? "aucun" : projects.map { "\($0.name) (\($0.kind.name))" }.joined(separator: ", ")
        let kindList = ProjectKind.allCases.map { "\($0.rawValue) (\($0.name))" }.joined(separator: ", ")
        return """
            Tu peux aussi agir sur son Mac, avec une seule action par réponse :
            - open_editor : ouvrir un éditeur (champ editor).
            - open_project : ouvrir un de ses projets (champ project) avec un éditeur, « Finder » ou « Terminal » \
            (champ editor ; vide pour son éditeur habituel).
            - create_project : créer un projet (champs kind, name et editor) ; tu le ranges toi-même dans le \
            bon dossier, avec ses fichiers de départ et un dépôt Git, puis tu l'ouvres dans l'éditeur.
            - none : juste répondre.
            Ses éditeurs : \(editorList).
            Ses projets : \(projectList).
            Genres de projet (champ kind) : \(kindList).
            N'utilise que ces éditeurs, ces projets et ces genres. S'il manque une information importante \
            (l'éditeur quand il en a plusieurs et ne l'a pas précisé, le nom d'un nouveau projet…), pose la \
            question avec l'action none : il te répondra au message suivant. Sinon, agis tout de suite et dis \
            en une phrase ce que tu fais (« J'ouvre Cursor ! »). Les champs inutiles de l'action restent vides.
            Réponds au format JSON demandé : reply (ta phrase) et action.
            """
    }

    static var format: AIPrompt.Format {
        let fields = ["type", "editor", "project", "kind", "name"]
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "reply": ["type": "string"],
                "action": [
                    "type": "object",
                    "properties": [
                        "type": ["type": "string", "enum": types],
                        "editor": ["type": "string"],
                        "project": ["type": "string"],
                        "kind": ["type": "string"],
                        "name": ["type": "string"],
                    ],
                    "required": fields,
                    "additionalProperties": false,
                ],
            ],
            "required": ["reply", "action"],
            "additionalProperties": false,
        ]
        let openAPISchema: [String: Any] = [
            "type": "OBJECT",
            "properties": [
                "reply": ["type": "STRING"],
                "action": [
                    "type": "OBJECT",
                    "properties": [
                        "type": ["type": "STRING", "enum": types],
                        "editor": ["type": "STRING"],
                        "project": ["type": "STRING"],
                        "kind": ["type": "STRING"],
                        "name": ["type": "STRING"],
                    ],
                    "required": fields,
                ],
            ],
            "required": ["reply", "action"],
        ]
        return AIPrompt.Format(name: "zebo_reply", schema: schema, openAPISchema: openAPISchema)
    }

    static func answer(fromJSON text: String) -> Answer? {
        try? JSONDecoder().decode(Answer.self, from: Data(text.utf8))
    }

    // MARK: - De la demande à l'action

    /// L'action décrite par l'IA, avec les vrais éditeurs et projets ; `nil` pour « none ».
    static func resolve(_ request: Request, editors: [IDEChoice], projects: [ZeboProject]) throws(ZeboActionError)
        -> ZeboAction?
    {
        switch request.type {
        case "open_editor":
            return .openEditor(try editor(named: request.editor, among: editors))

        case "open_project":
            guard let project = best(projects, matching: request.project, by: \.name) else {
                throw ZeboActionError("Je ne trouve pas le projet « \(request.project) ».")
            }
            return .openProject(project, with: try target(named: request.editor, for: project, among: editors))

        case "create_project":
            guard let kind = ProjectKind(rawValue: request.kind.lowercased()) else {
                throw ZeboActionError("Je ne sais pas créer de projet « \(request.kind) ».")
            }
            let name = ProjectScaffolder.folderName(for: request.name)
            guard ProjectScaffolder.isValidName(name) else {
                throw ZeboActionError("Il me faut un nom de projet utilisable comme nom de dossier.")
            }
            let editor = request.editor.isEmpty ? nil : try editor(named: request.editor, among: editors)
            return .createProject(name: name, kind: kind, editor: editor)

        default:
            return nil
        }
    }

    private static func editor(named name: String, among editors: [IDEChoice]) throws(ZeboActionError) -> IDEChoice {
        guard let editor = best(editors, matching: name, by: \.name) else {
            throw ZeboActionError("Je ne trouve pas l'éditeur « \(name) » sur ton Mac.")
        }
        return editor
    }

    /// Avec quoi ouvrir un projet : l'éditeur nommé, le Finder, le Terminal, ou à défaut son éditeur habituel.
    private static func target(named name: String, for project: ZeboProject, among editors: [IDEChoice])
        throws(ZeboActionError) -> ProjectOpenTarget
    {
        switch normalized(name) {
        case "":
            return project.editor.map(ProjectOpenTarget.editor) ?? editors.first.map(ProjectOpenTarget.editor)
                ?? .finder
        case "finder": return .finder
        case "terminal": return .terminal
        default: return .editor(try editor(named: name, among: editors))
        }
    }

    /// Le nom identique (sans tenir compte des majuscules ni des accents), sinon le premier qui le contient.
    static func best<Item>(_ items: [Item], matching query: String, by name: (Item) -> String) -> Item? {
        let query = normalized(query)
        guard !query.isEmpty else { return nil }
        return items.first { normalized(name($0)) == query }
            ?? items.first { normalized(name($0)).contains(query) || query.contains(normalized(name($0))) }
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
