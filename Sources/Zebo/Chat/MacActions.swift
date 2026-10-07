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

    func perform(_ action: ZeboAction, terminal: ZeboTerminal) async throws -> ZeboActionResult {
        switch action {
        case .listFiles(let project, let path):
            return try ProjectFiles.list(path, in: project)

        case .readFile(let project, let path):
            return try ProjectFiles.read(path, in: project)

        case .writeFile(let project, let path, let content):
            let result = try ProjectFiles.write(path, content: content, in: project)
            terminal.note("✎ \(path)", in: project.path)
            return result

        case .runCommand(let project, let command):
            return try await run(command, in: project, terminal: terminal)

        default:
            return ZeboActionResult(try await performOnTheMac(action))
        }
    }

    /// Lance la commande et dit comment elle s'est terminée ; l'IA reçoit la fin de sa sortie.
    private func run(_ command: String, in project: ZeboProject, terminal: ZeboTerminal) async throws
        -> ZeboActionResult
    {
        let outcome = try await CommandRunner.run(command, in: ProjectFiles.projectRoot(project), terminal: terminal)
        let summary: String
        if outcome.didTimeOut {
            summary = "« \(command) » a dépassé 5 minutes : je l'ai arrêtée."
        } else if outcome.exitCode == 0 {
            summary = "« \(command) » a réussi."
        } else {
            summary = "« \(command) » a échoué (code \(outcome.exitCode))."
        }
        let output = outcome.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return ZeboActionResult(
            summary,
            details: "Code de sortie : \(outcome.exitCode)\nSortie (fin) :\n\(output.isEmpty ? "(rien)" : output)")
    }

    /// Ouvrir un éditeur ou un projet, créer un projet.
    private func performOnTheMac(_ action: ZeboAction) async throws -> String {
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

        case .listFiles, .readFile, .writeFile, .runCommand:
            preconditionFailure("Les étapes de code sont faites par perform(_:terminal:).")
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
