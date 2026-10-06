import Foundation

/// Crée un nouveau projet sur le disque : son dossier dans le workspace, et ses fichiers de départ.
public struct ProjectScaffolder: Sendable {
    public enum Failure: Error, Equatable {
        /// Le nom est vide ou contient un caractère interdit dans un nom de dossier.
        case invalidName
        /// Un dossier porte déjà ce nom dans le workspace.
        case alreadyExists(path: String)
    }

    public init() {}

    /// Le nom de dossier du projet : le nom tapé, sans espaces autour.
    public static func folderName(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Un nom utilisable comme nom de dossier.
    public static func isValidName(_ name: String) -> Bool {
        let folder = folderName(for: name)
        return !folder.isEmpty && !folder.hasPrefix(".") && folder.rangeOfCharacter(from: ["/", ":"]) == nil
    }

    /// Crée le projet (et le workspace s'il n'existe pas encore). Ne remplace jamais un dossier existant.
    /// - Returns: le dossier du projet.
    @discardableResult
    public func createProject(named name: String, kind: ProjectKind, in workspace: URL) throws -> URL {
        guard Self.isValidName(name) else { throw Failure.invalidName }
        let fileManager = FileManager.default
        let project = workspace.appending(path: Self.folderName(for: name), directoryHint: .isDirectory)
        guard !fileManager.fileExists(atPath: project.path) else {
            throw Failure.alreadyExists(path: project.path)
        }
        try fileManager.createDirectory(at: project, withIntermediateDirectories: true)
        for (path, contents) in ProjectTemplate.files(for: kind, name: Self.folderName(for: name)) {
            let file = project.appending(path: path)
            try fileManager.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(contents.utf8).write(to: file, options: .withoutOverwriting)
        }
        return project
    }
}
