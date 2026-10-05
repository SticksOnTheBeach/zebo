import AppKit
import ZeboCore

/// Retrouve un éditeur comme le ferait le Finder : d'abord par son identifiant (macOS connaît
/// les apps où qu'elles soient), puis dans les dossiers d'applications habituels.
struct WorkspaceApplicationLocator: ApplicationLocator {
    func locate(_ ide: IDE) -> URL? {
        for identifier in ide.bundleIdentifiers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
                return url
            }
        }
        let fileManager = FileManager.default
        for folder in Self.applicationFolders {
            for name in ide.appNames {
                let url = folder.appending(path: name)
                if fileManager.fileExists(atPath: url.path) { return url }
            }
        }
        return nil
    }

    /// Là où l'on installe des apps, y compris JetBrains Toolbox.
    private static var applicationFolders: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            URL(fileURLWithPath: "/Applications"),
            home.appending(path: "Applications"),
            home.appending(path: "Applications/JetBrains Toolbox"),
        ]
    }
}
