import Foundation
import ZeboCore

/// Décrit les dossiers d'un dossier de projets (deux niveaux), sans lire leurs fichiers :
/// seulement combien il y en a de chaque extension. Sert à repérer les workspaces.
struct FolderScanner {
    /// Dossiers lourds ou générés, jamais comptés.
    private static let skippedFolders: Set<String> = [
        "node_modules", ".build", "build", "Pods", "DerivedData", "vendor", "target", "dist", ".venv", "venv",
    ]
    /// Au-delà, on arrête de compter : l'ordre de grandeur suffit.
    private static let maxFilesPerFolder = 5000
    private static let maxCountingDepth = 5

    /// Les dossiers à deux niveaux sous `root`, triés par chemin.
    func scan(_ root: URL) async -> [FolderSummary] {
        await Task.detached(priority: .userInitiated) {
            Self.summaries(in: root)
        }.value
    }

    private static func summaries(in root: URL) -> [FolderSummary] {
        var summaries: [FolderSummary] = []
        for folder in subfolders(of: root) {
            summaries.append(summary(of: folder, root: root))
            for child in subfolders(of: folder) {
                summaries.append(summary(of: child, root: root))
            }
        }
        return summaries.sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }
    }

    private static func subfolders(of url: URL) -> [URL] {
        let children =
            (try? FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        return children.filter { child in
            !skippedFolders.contains(child.lastPathComponent)
                && (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }
    }

    private static func summary(of folder: URL, root: URL) -> FolderSummary {
        var counts: [String: Int] = [:]
        var total = 0
        var queue: [(url: URL, depth: Int)] = [(folder, 0)]
        while let (url, depth) = queue.popLast(), total < maxFilesPerFolder {
            let children =
                (try? FileManager.default.contentsOfDirectory(
                    at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
            for child in children {
                if (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    if depth < maxCountingDepth, !skippedFolders.contains(child.lastPathComponent) {
                        queue.append((child, depth + 1))
                    }
                } else if !child.pathExtension.isEmpty {
                    counts[child.pathExtension.lowercased(), default: 0] += 1
                    total += 1
                }
            }
        }
        let relativePath = String(folder.path.dropFirst(root.path.count).drop { $0 == "/" })
        let isGit = FileManager.default.fileExists(atPath: folder.appending(path: ".git").path)
        return FolderSummary(
            path: folder.path, relativePath: relativePath, fileCounts: counts, isGitRepository: isGit)
    }
}
