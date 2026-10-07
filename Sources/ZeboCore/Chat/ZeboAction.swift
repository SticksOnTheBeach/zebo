import Foundation

/// Ce que Zebo sait faire sur le Mac quand on le lui demande dans la discussion. La liste est fermée :
/// l'IA choisit une de ces actions et ses paramètres. Pour coder, il lit et écrit des fichiers et lance
/// des commandes, toujours dans le dossier d'un projet.
public enum ZeboAction: Equatable, Sendable {
    /// Ouvrir un éditeur.
    case openEditor(IDEChoice)
    /// Ouvrir un projet connu avec un éditeur, le Finder ou le Terminal.
    case openProject(ZeboProject, with: ProjectOpenTarget)
    /// Créer un projet (rangé dans le bon workspace), puis l'ouvrir dans l'éditeur donné.
    case createProject(name: String, kind: ProjectKind, editor: IDEChoice?)
    /// Lister un dossier du projet (chemin relatif ; vide pour la racine).
    case listFiles(ZeboProject, path: String)
    /// Lire un fichier du projet.
    case readFile(ZeboProject, path: String)
    /// Écrire (ou remplacer) un fichier du projet.
    case writeFile(ZeboProject, path: String, content: String)
    /// Lancer une commande dans le dossier du projet.
    case runCommand(ZeboProject, command: String)

    /// Ce que Zebo est en train de faire, affiché sous sa réponse.
    public var progressText: String {
        switch self {
        case .openEditor(let editor): "J'ouvre \(editor.name)…"
        case .openProject(let project, _): "J'ouvre « \(project.name) »…"
        case .createProject(let name, let kind, _): "Je crée « \(name) » (\(kind.name))…"
        case .listFiles(_, let path): "Je regarde \(path.isEmpty ? "le projet" : path)…"
        case .readFile(_, let path): "Je lis \(path)…"
        case .writeFile(_, let path, _): "J'écris \(path)…"
        case .runCommand(_, let command): "❯ \(command)"
        }
    }

    /// Une étape de code (lire, écrire, lancer) : son résultat repart à l'IA, qui enchaîne.
    public var isCodingStep: Bool {
        switch self {
        case .listFiles, .readFile, .writeFile, .runCommand: true
        case .openEditor, .openProject, .createProject: false
        }
    }
}

/// Ce qu'une action a donné : une phrase pour la discussion, et le détail pour l'IA
/// (la sortie d'une commande, le contenu d'un fichier…).
public struct ZeboActionResult: Equatable, Sendable {
    public var summary: String
    public var details: String?

    public init(_ summary: String, details: String? = nil) {
        self.summary = summary
        self.details = details
    }
}

/// Une action impossible, avec sa raison en une phrase.
public struct ZeboActionError: Error, Equatable, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}

/// Fait ce que Zebo a décidé : c'est l'app qui ouvre les apps, écrit les fichiers et lance les commandes.
@MainActor
public protocol ZeboActionPerformer: AnyObject {
    /// Les éditeurs que Zebo peut ouvrir : ceux choisis à la configuration, puis ceux trouvés sur le Mac.
    var editors: [IDEChoice] { get }
    /// Les projets que Zebo connaît.
    var projects: [ZeboProject] { get }
    /// Fait l'action ; une commande affiche sa sortie, en direct, dans le terminal.
    func perform(_ action: ZeboAction, terminal: ZeboTerminal) async throws -> ZeboActionResult
}
