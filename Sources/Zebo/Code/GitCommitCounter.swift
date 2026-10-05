import Foundation
import ZeboCore

/// Compte avec Git les commits faits aujourd'hui (depuis minuit) par l'utilisateur,
/// dans tous les dépôts d'un dossier de projets.
struct GitCommitCounter: CommitCounter {
    /// Profondeur maximale de recherche des dépôts dans le dossier.
    private static let maxDepth = 4
    /// Dossiers lourds où l'on ne cherche jamais de dépôt.
    private static let skippedFolders: Set<String> = [
        "node_modules", ".build", "build", "Pods", "DerivedData", "vendor", "target", "dist", ".venv",
    ]

    func commitsToday(in folder: URL) async -> Int? {
        await Task.detached(priority: .utility) {
            Self.countCommitsToday(in: folder)
        }.value
    }

    private static func countCommitsToday(in folder: URL) -> Int? {
        guard FileManager.default.fileExists(atPath: folder.path) else { return nil }
        // Sans adresse Git, on compte tous les commits du jour.
        let author = git(["config", "--global", "user.email"])?.trimmingCharacters(in: .whitespacesAndNewlines)
        var hashes = Set<String>()
        for repository in repositories(in: folder) {
            var arguments = ["-C", repository.path, "log", "--all", "--since=midnight", "--format=%H"]
            if let author, !author.isEmpty { arguments.append("--author=\(author)") }
            guard let output = git(arguments) else { continue }
            // Un même commit présent dans plusieurs dépôts (clone, fork) ne compte qu'une fois.
            hashes.formUnion(output.split(separator: "\n").map(String.init))
        }
        return hashes.count
    }

    /// Les dossiers contenant un `.git`, y compris les dépôts rangés dans un autre dépôt.
    private static func repositories(in folder: URL) -> [URL] {
        let fileManager = FileManager.default
        var found: [URL] = []
        var queue: [(url: URL, depth: Int)] = [(folder, 0)]
        while let (url, depth) = queue.popLast() {
            if fileManager.fileExists(atPath: url.appending(path: ".git").path) {
                found.append(url)
            }
            guard depth < maxDepth,
                let children = try? fileManager.contentsOfDirectory(
                    at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            else { continue }
            for child in children where !skippedFolders.contains(child.lastPathComponent) {
                if (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    queue.append((child, depth + 1))
                }
            }
        }
        return found
    }

    /// Lance Git et renvoie sa sortie, ou `nil` s'il échoue.
    private static func git(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
