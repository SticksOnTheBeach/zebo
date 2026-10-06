import Foundation
import Observation

/// Les étapes de la création d'un projet : son genre, son nom, son workspace (que Zebo cherche,
/// avec l'IA si possible), puis l'éditeur où l'ouvrir.
@MainActor
@Observable
public final class NewProjectWizard {
    public enum Step: Int, CaseIterable, Comparable, Sendable {
        case kind
        case name
        case workspace
        case editor

        public static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Où créer le projet.
    public enum WorkspaceChoice: Equatable, Sendable {
        /// Dans un workspace qui existe déjà.
        case existing(path: String)
        /// Dans un nouveau workspace (créé avec le projet).
        case new(path: String)

        public var path: String {
            switch self {
            case .existing(let path), .new(let path): path
            }
        }
    }

    /// La recherche des workspaces du genre choisi.
    public enum Search: Equatable, Sendable {
        case idle
        case searching
        case done(WorkspaceAdvice)
    }

    public private(set) var step: Step = .kind
    public private(set) var isMovingForward = true

    public var kind: ProjectKind? {
        didSet { if kind != oldValue { resetWorkspace() } }
    }
    public var name = ""
    public var workspace: WorkspaceChoice?
    public private(set) var search: Search = .idle
    /// L'éditeur où ouvrir le projet (aucun : ne pas l'ouvrir).
    public var editor: IDEChoice?

    /// Les éditeurs choisis pendant la configuration.
    public let editors: [IDEChoice]
    /// Le dossier des projets, où chercher les workspaces.
    public let projectsFolder: URL

    @ObservationIgnored private let scan: @Sendable (URL) async -> [FolderSummary]
    @ObservationIgnored private let advisor: any WorkspaceAdvisor
    @ObservationIgnored private let folderExists: (String) -> Bool

    public init(
        projectsFolder: URL, editors: [IDEChoice], advisor: any WorkspaceAdvisor,
        scan: @escaping @Sendable (URL) async -> [FolderSummary],
        folderExists: @escaping (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        self.projectsFolder = projectsFolder
        self.editors = editors
        self.advisor = advisor
        self.scan = scan
        self.folderExists = folderExists
        editor = editors.first
    }

    // MARK: - Navigation

    public var canGoBack: Bool { step != .kind }
    public var isLastStep: Bool { step == .editor }

    public var canAdvance: Bool {
        switch step {
        case .kind: kind != nil
        case .name: ProjectScaffolder.isValidName(name)
        case .workspace: workspace != nil && search != .searching && !isProjectFolderTaken
        case .editor: false
        }
    }

    public func advance() {
        guard canAdvance, let next = Step(rawValue: step.rawValue + 1) else { return }
        isMovingForward = true
        step = next
    }

    public func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        isMovingForward = false
        step = previous
    }

    // MARK: - Workspace

    /// Un nouveau workspace pour ce genre, dans le dossier des projets (ex. « …/Dev/C++ ») ;
    /// si ce dossier existe déjà, le premier nom libre (« C++ 2 », « C++ 3 »…).
    public var suggestedNewWorkspace: String? {
        guard let kind else { return nil }
        let base = kind.suggestedWorkspaceName
        let candidates = [base] + (2...99).map { "\(base) \($0)" }
        let free = candidates.first { !folderExists(projectsFolder.appending(path: $0).path) }
        return projectsFolder.appending(path: free ?? base).path
    }

    /// Cherche les workspaces du genre choisi, puis propose le plus probable
    /// (ou, s'il n'y en a pas, un nouveau workspace).
    public func searchWorkspaces() async {
        guard let kind, search == .idle else { return }
        search = .searching
        let folders = await scan(projectsFolder)
        let advice =
            await (try? advisor.adviseWorkspaces(for: kind, among: folders))
            ?? WorkspaceAdvice(workspaces: [], source: .local)
        // Le genre a pu changer pendant la recherche : la réponse ne vaut plus rien.
        guard self.kind == kind else { return }
        search = .done(advice)
        if workspace == nil {
            if let best = advice.workspaces.first {
                workspace = .existing(path: best.path)
            } else if let suggested = suggestedNewWorkspace {
                workspace = .new(path: suggested)
            }
        }
    }

    private func resetWorkspace() {
        search = .idle
        workspace = nil
    }

    // MARK: - Résultat

    /// Le dossier du futur projet.
    public var projectPath: String? {
        workspace.map { URL(fileURLWithPath: $0.path).appending(path: ProjectScaffolder.folderName(for: name)).path }
    }

    /// Un dossier porte déjà ce nom dans le workspace choisi.
    public var isProjectFolderTaken: Bool {
        projectPath.map(folderExists) ?? false
    }
}
