import Foundation

/// Un dossier qui pourrait servir de workspace : ce qu'on sait de lui sans lire ses fichiers.
public struct FolderSummary: Codable, Equatable, Sendable {
    /// Chemin complet.
    public var path: String
    /// Chemin depuis le dossier de projets (ex. « Web » ou « Web/zebo »).
    public var relativePath: String
    /// Nombre de fichiers par extension (en minuscules, sans le point).
    public var fileCounts: [String: Int]
    /// C'est un dépôt Git : plutôt un projet qu'un workspace.
    public var isGitRepository: Bool

    public init(path: String, relativePath: String, fileCounts: [String: Int], isGitRepository: Bool) {
        self.path = path
        self.relativePath = relativePath
        self.fileCounts = fileCounts
        self.isGitRepository = isGitRepository
    }

    public var name: String { (relativePath as NSString).lastPathComponent }

    /// Nombre de fichiers de ce genre de projet.
    public func count(of kind: ProjectKind) -> Int {
        kind.fileExtensions.reduce(0) { $0 + (fileCounts[$1] ?? 0) }
    }

    public var totalFiles: Int { fileCounts.values.reduce(0, +) }
}

/// Un workspace proposé, et pourquoi.
public struct WorkspaceSuggestion: Equatable, Sendable {
    public var path: String
    public var reason: String

    public init(path: String, reason: String) {
        self.path = path
        self.reason = reason
    }
}

/// Les workspaces trouvés pour un genre de projet, du plus probable au moins probable.
public struct WorkspaceAdvice: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        /// Jugé par l'IA.
        case ai
        /// Deviné localement (noms de dossiers, extensions).
        case local
    }

    public var workspaces: [WorkspaceSuggestion]
    public var source: Source

    public init(workspaces: [WorkspaceSuggestion], source: Source) {
        self.workspaces = workspaces
        self.source = source
    }
}

/// Repère, parmi les dossiers de projets, ceux qui servent de workspace pour un genre de projet.
public protocol WorkspaceAdvisor: Sendable {
    func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async throws -> WorkspaceAdvice
}

/// Sans IA : un dossier est un workspace si son nom l'annonce (« C++ », « Web »…)
/// ou si la plupart de ses fichiers sont de ce genre.
public struct LocalWorkspaceAdvisor: WorkspaceAdvisor {
    public init() {}

    public func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async -> WorkspaceAdvice {
        let scored = folders.compactMap { folder -> (score: Int, files: Int, suggestion: WorkspaceSuggestion)? in
            var score = 0
            var reasons: [String] = []
            if kind.folderNameHints.contains(folder.name.lowercased()) {
                score += 3
                reasons.append("son nom correspond à \(kind.name)")
            }
            let files = folder.count(of: kind)
            let share = folder.totalFiles > 0 ? Double(files) / Double(folder.totalFiles) : 0
            if files >= 3, share >= 0.5 {
                score += 2
                reasons.append("la plupart de ses fichiers sont en \(kind.name) (\(files))")
            } else if files > 0, share >= 0.25 {
                score += 1
                reasons.append("il contient des fichiers \(kind.name) (\(files))")
            }
            // Un dépôt Git est plutôt un projet qu'un dossier qui en range plusieurs.
            if folder.isGitRepository { score -= 1 }
            guard score >= 2 else { return nil }
            let reason = reasons.joined(separator: ", ").capitalizedFirstLetter + "."
            return (score, files, WorkspaceSuggestion(path: folder.path, reason: reason))
        }
        let workspaces =
            scored
            .sorted { ($0.score, $0.files) > ($1.score, $1.files) }
            .map(\.suggestion)
        return WorkspaceAdvice(workspaces: workspaces, source: .local)
    }
}

extension String {
    fileprivate var capitalizedFirstLetter: String {
        prefix(1).uppercased() + dropFirst()
    }
}
