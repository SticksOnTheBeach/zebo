import Testing

@testable import ZeboCore

@Suite("Repérage local des workspaces")
struct LocalWorkspaceAdvisorTests {
    private let advisor = LocalWorkspaceAdvisor()

    private func folder(_ relativePath: String, _ files: [String: Int] = [:], git: Bool = false) -> FolderSummary {
        FolderSummary(
            path: "/Users/me/Dev/" + relativePath, relativePath: relativePath, fileCounts: files, isGitRepository: git)
    }

    @Test("Un dossier nommé comme le langage est un workspace")
    func folderNamedAfterTheKind() async {
        let advice = await advisor.adviseWorkspaces(for: .cpp, among: [folder("C++"), folder("Java")])
        #expect(advice.workspaces.map(\.path) == ["/Users/me/Dev/C++"])
        #expect(advice.source == .local)
    }

    @Test("Un dossier rempli de fichiers du langage est un workspace")
    func folderFullOfMatchingFiles() async {
        let advice = await advisor.adviseWorkspaces(
            for: .python, among: [folder("scripts", ["py": 12, "md": 2]), folder("notes", ["md": 30])])
        #expect(advice.workspaces.map(\.path) == ["/Users/me/Dev/scripts"])
    }

    @Test("Un dossier mal nommé avec trop peu de fichiers du langage n'en est pas un")
    func weakMatchIsIgnored() async {
        let advice = await advisor.adviseWorkspaces(for: .rust, among: [folder("misc", ["rs": 1, "txt": 20])])
        #expect(advice.workspaces.isEmpty)
    }

    @Test("Le nom et les fichiers ensemble passent devant les fichiers seuls")
    func bestMatchFirst() async {
        let advice = await advisor.adviseWorkspaces(
            for: .web,
            among: [folder("experiments", ["js": 40]), folder("Web", ["html": 10, "css": 8])])
        #expect(advice.workspaces.first?.path == "/Users/me/Dev/Web")
        #expect(advice.workspaces.count == 2)
    }

    @Test("Un dépôt Git compte moins qu'un dossier qui range des projets")
    func gitRepositoryIsLessLikely() async {
        let advice = await advisor.adviseWorkspaces(
            for: .swift, among: [folder("Swift", ["swift": 5], git: true), folder("Apple", ["swift": 5])])
        #expect(advice.workspaces.first?.path == "/Users/me/Dev/Apple")
    }

    @Test("La raison explique le choix")
    func reasonExplainsTheChoice() async {
        let advice = await advisor.adviseWorkspaces(for: .c, among: [folder("C", ["c": 4, "h": 2])])
        #expect(advice.workspaces.first?.reason == "Son nom correspond à C, la plupart de ses fichiers sont en C (6).")
    }
}
