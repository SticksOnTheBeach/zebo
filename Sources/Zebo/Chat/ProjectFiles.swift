import Foundation
import ZeboCore

/// Les fichiers d'un projet, tels que Zebo les lit et les écrit quand il code. Un chemin qui sortirait
/// du dossier du projet (même par un lien symbolique) est refusé.
enum ProjectFiles {
    /// Dossiers qu'on ne liste pas : trop gros, ou sans intérêt pour coder.
    static let skipped: Set<String> = [".git", "node_modules", ".build", "build", "dist", ".next", "target", ".idea"]
    static let maxListed = 400
    static let maxReadBytes = 200_000

    static func list(_ path: String, in project: ZeboProject) throws -> ZeboActionResult {
        let folder = try url(path, in: project)
        let root = try projectRoot(project)
        var entries: [String] = []
        let enumerator = FileManager.default.enumerator(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsPackageDescendants])
        while let item = enumerator?.nextObject() as? URL, entries.count < maxListed {
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory, skipped.contains(item.lastPathComponent) {
                enumerator?.skipDescendants()
                continue
            }
            if enumerator?.level ?? 0 > 4 { enumerator?.skipDescendants() }
            let relative = String(item.standardizedFileURL.path.dropFirst(root.path.count + 1))
            entries.append(isDirectory ? relative + "/" : relative)
        }
        let shown = path.isEmpty ? "le projet" : path
        let details = entries.isEmpty ? "(vide)" : entries.sorted().joined(separator: "\n")
        return ZeboActionResult("J'ai regardé \(shown) (\(entries.count) éléments).", details: details)
    }

    static func read(_ path: String, in project: ZeboProject) throws -> ZeboActionResult {
        let file = try url(path, in: project)
        guard let data = FileManager.default.contents(atPath: file.path) else {
            throw ZeboActionError("\(path) n'existe pas.")
        }
        guard data.count <= maxReadBytes, let text = String(data: data, encoding: .utf8) else {
            throw ZeboActionError("\(path) est trop gros, ou n'est pas du texte.")
        }
        return ZeboActionResult("J'ai lu \(path).", details: text)
    }

    static func write(_ path: String, content: String, in project: ZeboProject) throws -> ZeboActionResult {
        let file = try url(path, in: project)
        do {
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(content.utf8).write(to: file, options: .atomic)
        } catch {
            throw ZeboActionError("Je n'ai pas pu écrire \(path) : \(error.localizedDescription)")
        }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).count
        return ZeboActionResult("\(path) écrit (\(lines) lignes).")
    }

    /// Le dossier du projet, liens symboliques résolus.
    static func projectRoot(_ project: ZeboProject) throws -> URL {
        let root = URL(fileURLWithPath: project.path).resolvingSymlinksInPath().standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue
        else { throw ZeboActionError("Le dossier de « \(project.name) » n'existe plus.") }
        return root
    }

    /// Le fichier, dans le projet et nulle part ailleurs.
    static func url(_ path: String, in project: ZeboProject) throws -> URL {
        let root = try projectRoot(project)
        let file = root.appending(path: path).resolvingSymlinksInPath().standardizedFileURL
        guard file.path == root.path || file.path.hasPrefix(root.path + "/") else {
            throw ZeboActionError("« \(path) » sort du projet : je reste dans son dossier.")
        }
        return file
    }
}
