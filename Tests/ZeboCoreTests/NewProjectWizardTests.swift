import Foundation
import Testing

@testable import ZeboCore

@MainActor
@Suite("Assistant de nouveau projet")
struct NewProjectWizardTests {
    private struct FixedAdvisor: WorkspaceAdvisor {
        let paths: [String]
        func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async -> WorkspaceAdvice {
            WorkspaceAdvice(workspaces: paths.map { WorkspaceSuggestion(path: $0, reason: "") }, source: .ai(.claude))
        }
    }

    private let root = URL(fileURLWithPath: "/Users/me/Dev")
    private let vscode = IDEChoice(id: "vscode", name: "VS Code", path: "/Applications/Visual Studio Code.app")

    private func makeWizard(found paths: [String] = []) -> NewProjectWizard {
        NewProjectWizard(
            projectsFolder: root, editors: [vscode], advisor: FixedAdvisor(paths: paths), scan: { _ in [] },
            folderExists: { _ in false })
    }

    @Test("On choisit d'abord un genre, puis un nom valide")
    func kindThenName() {
        let wizard = makeWizard()
        #expect(!wizard.canAdvance)
        wizard.kind = .cpp
        wizard.advance()
        #expect(wizard.step == .name)
        wizard.name = "a/b"
        #expect(!wizard.canAdvance)
        wizard.name = "Mon jeu"
        wizard.advance()
        #expect(wizard.step == .workspace)
    }

    @Test("Un workspace trouvé est proposé en premier")
    func proposesFoundWorkspace() async {
        let wizard = makeWizard(found: ["/Users/me/Dev/C++", "/Users/me/Dev/Autre"])
        wizard.kind = .cpp
        await wizard.searchWorkspaces()
        #expect(wizard.workspace == .existing(path: "/Users/me/Dev/C++"))
        guard case .done(let advice) = wizard.search else {
            Issue.record("pas de résultat")
            return
        }
        #expect(advice.workspaces.count == 2)
    }

    @Test("Sans workspace trouvé, Zebo en propose un nouveau dans le dossier des projets")
    func proposesNewWorkspace() async {
        let wizard = makeWizard()
        wizard.kind = .rust
        await wizard.searchWorkspaces()
        #expect(wizard.workspace == .new(path: "/Users/me/Dev/Rust"))
    }

    @Test("Un nouveau workspace ne reprend pas le nom d'un dossier qui existe déjà")
    func newWorkspaceAvoidsExistingFolders() {
        let existing: Set<String> = ["/Users/me/Dev/C++", "/Users/me/Dev/C++ 2"]
        let wizard = NewProjectWizard(
            projectsFolder: root, editors: [], advisor: FixedAdvisor(paths: []), scan: { _ in [] },
            folderExists: { existing.contains($0) })
        wizard.kind = .cpp
        #expect(wizard.suggestedNewWorkspace == "/Users/me/Dev/C++ 3")
    }

    @Test("Changer de genre oublie le workspace choisi")
    func changingKindResetsWorkspace() async {
        let wizard = makeWizard(found: ["/Users/me/Dev/C++"])
        wizard.kind = .cpp
        await wizard.searchWorkspaces()
        wizard.kind = .web
        #expect(wizard.workspace == nil)
        #expect(wizard.search == .idle)
    }

    @Test("Le projet est rangé dans le workspace, sous son nom")
    func projectPath() {
        let wizard = makeWizard()
        wizard.name = "  Mon jeu "
        wizard.workspace = .existing(path: "/Users/me/Dev/C++")
        #expect(wizard.projectPath == "/Users/me/Dev/C++/Mon jeu")
    }

    @Test("Le premier éditeur configuré est proposé d'office")
    func defaultEditor() {
        #expect(makeWizard().editor == vscode)
    }
}

@MainActor
@Suite("Bibliothèque des projets")
struct ProjectsLibraryTests {
    private final class MemoryStore: ProjectsStore {
        var saved: [ZeboProject] = []
        func loadProjects() -> [ZeboProject] { saved }
        func saveProjects(_ projects: [ZeboProject]) { saved = projects }
    }

    @Test("Le dernier projet créé passe en premier, et c'est enregistré")
    func newestFirst() {
        let store = MemoryStore()
        let library = ProjectsLibrary(store: store)
        library.add(ZeboProject(name: "A", kind: .c, path: "/a"))
        library.add(ZeboProject(name: "B", kind: .web, path: "/b"))
        #expect(library.projects.map(\.name) == ["B", "A"])
        #expect(store.saved.map(\.name) == ["B", "A"])
    }

    @Test("Les projets disparus du disque sont oubliés")
    func forgetsMissingProjects() {
        let store = MemoryStore()
        store.saved = [ZeboProject(name: "A", kind: .c, path: "/a"), ZeboProject(name: "B", kind: .c, path: "/b")]
        let library = ProjectsLibrary(store: store)
        library.forgetMissing { $0 == "/b" }
        #expect(library.projects.map(\.name) == ["B"])
        #expect(store.saved.map(\.name) == ["B"])
    }

    @Test("L'éditeur choisi pour ouvrir un projet est retenu ; le Finder et le Terminal ne changent rien")
    func remembersTheEditor() {
        let store = MemoryStore()
        let library = ProjectsLibrary(store: store)
        let project = ZeboProject(name: "A", kind: .c, path: "/a")
        library.add(project)
        let xcode = IDEChoice(id: "xcode", name: "Xcode", path: "/Applications/Xcode.app")
        library.remember(.editor(xcode), for: project)
        #expect(library.projects.first?.editor == xcode)
        library.remember(.finder, for: project)
        library.remember(.terminal, for: project)
        #expect(store.saved.first?.editor == xcode)
    }
}
