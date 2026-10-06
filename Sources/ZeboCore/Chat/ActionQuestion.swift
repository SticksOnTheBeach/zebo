import Foundation

/// Quand Zebo peut agir, l'IA répond en JSON : sa phrase, l'action demandée (ou « none »), et peut-être
/// une initiative : une action en plus, qu'il propose et qu'on accepte ou refuse.
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

    /// Une action que Zebo propose de lui-même, avec la phrase qui la propose.
    struct Initiative: Decodable, Equatable {
        var text: String
        var action: Request
    }

    struct Answer: Decodable, Equatable {
        var reply: String
        var action: Request
        var initiative: Initiative?
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
            - create_project : créer un projet (champs kind, name et editor). Une fiche s'ouvre alors pour \
            qu'il choisisse le nom et l'éditeur : propose un nom court qui lui irait bien dans name, et \
            l'éditeur qui convient le mieux dans editor. Tu ranges ensuite le projet dans le bon dossier, \
            avec ses fichiers de départ et un dépôt Git, et tu l'ouvres dans l'éditeur.
            - none : juste répondre.
            Ses éditeurs : \(editorList).
            Ses projets : \(projectList).
            Genres de projet (champ kind) : \(kindList).
            N'utilise que ces éditeurs, ces projets et ces genres. S'il manque une information importante \
            (le genre d'un nouveau projet, l'éditeur à ouvrir quand il en a plusieurs…), pose la question avec \
            l'action none : il te répondra au message suivant. Sinon, agis tout de suite et dis en une phrase \
            ce que tu fais (« J'ouvre Cursor ! »). Les champs inutiles d'une action restent vides.
            Tu peux aussi prendre une initiative : proposer UNE action utile en plus de ce qu'il a demandé \
            (par exemple ouvrir le Terminal dans le projet que tu viens de créer, ou rouvrir un projet dont il \
            parle). Décris-la dans initiative, avec text, une phrase courte qui la propose (« Je t'ouvre aussi \
            le Terminal dans ce projet ? ») ; il pourra l'accepter ou la refuser. Une initiative se fait après \
            l'action : elle peut viser le projet que l'action crée. Sans initiative, son type est none. \
            N'en propose que si elle a du sens, pas à chaque message.
            Réponds au format JSON demandé : reply (ta phrase), action et initiative.
            """
    }

    static var format: AIPrompt.Format {
        AIPrompt.Format(name: "zebo_reply", schema: schema(openAPI: false), openAPISchema: schema(openAPI: true))
    }

    /// Le schéma de la réponse, en JSON Schema ou au format OpenAPI de Gemini (types en majuscules,
    /// sans `additionalProperties`).
    private static func schema(openAPI: Bool) -> [String: Any] {
        func type(_ name: String) -> String { openAPI ? name.uppercased() : name }
        func object(_ properties: [String: Any]) -> [String: Any] {
            var object: [String: Any] = [
                "type": type("object"), "properties": properties, "required": properties.keys.sorted(),
            ]
            if !openAPI { object["additionalProperties"] = false }
            return object
        }
        let string = ["type": type("string")]
        let request = object([
            "type": ["type": type("string"), "enum": types], "editor": string, "project": string,
            "kind": string, "name": string,
        ])
        return object([
            "reply": string, "action": request, "initiative": object(["text": string, "action": request]),
        ])
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
            // Le nom et l'éditeur ne sont que des propositions : la fiche « nouveau projet » les fait choisir.
            return .createProject(
                name: ProjectScaffolder.folderName(for: request.name), kind: kind,
                editor: best(editors, matching: request.editor, by: \.name))

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
