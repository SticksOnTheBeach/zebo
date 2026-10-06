import Foundation

/// Lance la commande `git` du Mac.
enum Git {
    /// Lance Git et renvoie sa sortie, ou `nil` s'il échoue.
    static func run(_ arguments: [String]) -> String? {
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

    /// Fait du dossier un dépôt Git (sans rien committer). Sans Git, le dossier reste tel quel.
    static func initializeRepository(at folder: URL) {
        _ = run(["-C", folder.path, "init", "--quiet"])
    }
}
