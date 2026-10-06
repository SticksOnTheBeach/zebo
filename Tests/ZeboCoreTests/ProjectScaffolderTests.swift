import Foundation
import Testing

@testable import ZeboCore

@Suite("Création des projets")
struct ProjectScaffolderTests {
    private let workspace = FileManager.default.temporaryDirectory
        .appending(path: "zebo-tests-\(UUID().uuidString)/C++")

    @Test("Le projet est créé dans le workspace, qui est créé s'il n'existait pas")
    func createsProjectAndWorkspace() throws {
        defer { try? FileManager.default.removeItem(at: workspace.deletingLastPathComponent()) }
        let project = try ProjectScaffolder().createProject(named: " Mon Jeu ", kind: .cpp, in: workspace)
        #expect(project.lastPathComponent == "Mon Jeu")
        let main = try String(contentsOf: project.appending(path: "main.cpp"), encoding: .utf8)
        #expect(main.contains("Hello depuis Mon Jeu"))
        let cmake = try String(contentsOf: project.appending(path: "CMakeLists.txt"), encoding: .utf8)
        #expect(cmake.contains("project(MonJeu CXX)"))
        #expect(FileManager.default.fileExists(atPath: project.appending(path: "README.md").path))
    }

    @Test("Un dossier existant n'est jamais remplacé")
    func neverOverwrites() throws {
        defer { try? FileManager.default.removeItem(at: workspace.deletingLastPathComponent()) }
        let scaffolder = ProjectScaffolder()
        let project = try scaffolder.createProject(named: "Jeu", kind: .c, in: workspace)
        #expect(throws: ProjectScaffolder.Failure.alreadyExists(path: project.path)) {
            try scaffolder.createProject(named: "Jeu", kind: .c, in: workspace)
        }
    }

    @Test("Un nom vide, caché ou avec une barre oblique est refusé", arguments: ["", "  ", ".cache", "a/b", "a:b"])
    func rejectsInvalidNames(name: String) {
        #expect(!ProjectScaffolder.isValidName(name))
        #expect(throws: ProjectScaffolder.Failure.invalidName) {
            try ProjectScaffolder().createProject(named: name, kind: .python, in: workspace)
        }
    }

    @Test("Chaque genre de projet a ses fichiers de départ", arguments: ProjectKind.allCases)
    func everyKindHasStarterFiles(kind: ProjectKind) {
        let files = ProjectTemplate.files(for: kind, name: "Démo")
        #expect(files.count >= 3)
        #expect(files.values.contains { $0.contains("Démo") })
    }

    @Test("Les noms de paquets sont nettoyés")
    func slugsAndIdentifiers() {
        #expect(ProjectTemplate.slug("Mon Super Jeu !") == "mon-super-jeu")
        #expect(ProjectTemplate.slug("Éléphant") == "elephant")
        #expect(ProjectTemplate.identifier("mon super jeu") == "MonSuperJeu")
        #expect(ProjectTemplate.identifier("2048") == "Projet2048")
    }
}
