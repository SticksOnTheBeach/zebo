import Foundation

/// Ce que Zebo sait faire sur le Mac quand on le lui demande dans la discussion. La liste est fermée :
/// l'IA choisit une de ces actions et ses paramètres, jamais une commande à exécuter.
public enum ZeboAction: Equatable, Sendable {
    /// Ouvrir un éditeur.
    case openEditor(IDEChoice)
    /// Ouvrir un projet connu avec un éditeur, le Finder ou le Terminal.
    case openProject(ZeboProject, with: ProjectOpenTarget)
    /// Créer un projet (rangé dans le bon workspace), puis l'ouvrir dans l'éditeur donné.
    case createProject(name: String, kind: ProjectKind, editor: IDEChoice?)

    /// Ce que Zebo est en train de faire, affiché sous sa réponse.
    public var progressText: String {
        switch self {
        case .openEditor(let editor): "J'ouvre \(editor.name)…"
        case .openProject(let project, _): "J'ouvre « \(project.name) »…"
        case .createProject(let name, let kind, _): "Je crée « \(name) » (\(kind.name))…"
        }
    }
}

/// Une action impossible, avec sa raison en une phrase.
public struct ZeboActionError: Error, Equatable, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}

/// Fait ce que Zebo a décidé : c'est l'app qui ouvre les apps et crée les dossiers.
@MainActor
public protocol ZeboActionPerformer: AnyObject {
    /// Les éditeurs que Zebo peut ouvrir : ceux choisis à la configuration, puis ceux trouvés sur le Mac.
    var editors: [IDEChoice] { get }
    /// Les projets que Zebo connaît.
    var projects: [ZeboProject] { get }
    /// Fait l'action et dit ce qui a été fait, en une phrase.
    func perform(_ action: ZeboAction) async throws -> String
}
