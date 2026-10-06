import AppKit
import ZeboCore

/// Ce que Zebo fait vraiment sur le Mac quand on le lui demande dans la discussion :
/// ouvrir un éditeur, ouvrir un projet, en créer un (rangé dans le bon workspace) et l'ouvrir.
@MainActor
final class MacActions: ZeboActionPerformer {
    private let settings: ZeboSettings
    private let library: ProjectsLibrary
    /// Les éditeurs du catalogue installés sur ce Mac, cherchés une seule fois.
    private lazy var installedEditors: [IDEChoice] = {
        let locator = WorkspaceApplicationLocator()
        return IDE.catalog.compactMap { ide in
            locator.locate(ide).map { IDEChoice(id: ide.id, name: ide.name, path: $0.path) }
        }
    }()

    init(settings: ZeboSettings, library: ProjectsLibrary) {
        self.settings = settings
        self.library = library
    }

    var editors: [IDEChoice] {
        let chosen = settings.preferences.ides
        let others = installedEditors.filter { editor in
            !chosen.contains { $0.id == editor.id || $0.path == editor.path }
        }
        return chosen + others
    }

    var projects: [ZeboProject] { library.projects }

    func perform(_ action: ZeboAction) async throws -> String {
        switch action {
        case .openEditor(let editor):
            try await open(editor)
            return "\(editor.name) est ouvert."

        case .openProject(let project, let target):
            guard FileManager.default.fileExists(atPath: project.path) else {
                throw ZeboActionError("Le dossier de « \(project.name) » n'existe plus.")
            }
            ProjectOpener.open(project, with: target)
            library.remember(target, for: project)
            return "« \(project.name) » est ouvert dans \(Self.name(of: target))."

        case .createProject(let name, let kind, let editor):
            return try await create(name, kind: kind, editor: editor)
        }
    }

    private func open(_ editor: IDEChoice) async throws {
        do {
            _ = try await NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: editor.path), configuration: NSWorkspace.OpenConfiguration())
        } catch {
            throw ZeboActionError("Je n'arrive pas à ouvrir \(editor.name).")
        }
    }

    /// Range le projet dans le workspace de son genre (ou un nouveau), le crée, puis l'ouvre.
    private func create(_ name: String, kind: ProjectKind, editor: IDEChoice?) async throws -> String {
        let preferences = settings.preferences
        let editor = editor ?? preferences.ides.first
        // Même logique que la fenêtre « Nouveau projet », sans nouvel appel à l'IA : c'est rapide.
        let wizard = NewProjectWizard(
            projectsFolder: ProjectsFolder.forNewProjects(preferences), editors: preferences.ides,
            advisor: LocalWorkspaceAdvisor(), scan: { await FolderScanner().scan($0) })
        wizard.kind = kind
        wizard.name = name
        await wizard.searchWorkspaces()
        guard let workspace = wizard.workspace else {
            throw ZeboActionError("Je ne sais pas où ranger ce projet.")
        }

        switch ProjectCreator.create(
            named: name, kind: kind, in: URL(fileURLWithPath: workspace.path), editor: editor)
        {
        case .success(let project):
            library.add(project)
            ProjectOpener.open(project)
            let place = (workspace.path as NSString).abbreviatingWithTildeInPath
            guard let editor else { return "« \(project.name) » est créé dans \(place)." }
            return "« \(project.name) » est créé dans \(place) et ouvert dans \(editor.name)."
        case .failure(let problem):
            throw ZeboActionError(problem.message)
        }
    }

    private static func name(of target: ProjectOpenTarget) -> String {
        switch target {
        case .editor(let editor): editor.name
        case .finder: "le Finder"
        case .terminal: "le Terminal"
        }
    }
}
