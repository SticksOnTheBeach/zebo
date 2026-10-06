import Foundation
import Observation

/// Un projet créé avec Zebo.
public struct ZeboProject: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: ProjectKind
    /// Dossier du projet.
    public var path: String
    public var createdAt: Date
    /// L'éditeur où l'ouvrir (aucun : on l'ouvre dans le Finder).
    public var editor: IDEChoice?

    public init(
        id: UUID = UUID(), name: String, kind: ProjectKind, path: String, createdAt: Date = Date(),
        editor: IDEChoice? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.path = path
        self.createdAt = createdAt
        self.editor = editor
    }
}

/// Retient les projets d'un lancement à l'autre.
@MainActor
public protocol ProjectsStore: AnyObject {
    func loadProjects() -> [ZeboProject]
    func saveProjects(_ projects: [ZeboProject])
}

/// Stockage dans les préférences de l'app, en JSON.
@MainActor
public final class UserDefaultsProjectsStore: ProjectsStore {
    private static let key = "projects"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadProjects() -> [ZeboProject] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([ZeboProject].self, from: data)) ?? []
    }

    public func saveProjects(_ projects: [ZeboProject]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

/// Les projets créés avec Zebo, du plus récent au plus ancien.
@MainActor
@Observable
public final class ProjectsLibrary {
    public private(set) var projects: [ZeboProject]

    @ObservationIgnored private let store: any ProjectsStore

    public init(store: any ProjectsStore) {
        self.store = store
        projects = store.loadProjects()
    }

    public func add(_ project: ZeboProject) {
        projects.insert(project, at: 0)
        store.saveProjects(projects)
    }

    /// Oublie les projets dont le dossier n'existe plus (supprimés ou déplacés).
    public func forgetMissing(exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) {
        let kept = projects.filter { exists($0.path) }
        guard kept.count != projects.count else { return }
        projects = kept
        store.saveProjects(projects)
    }
}
