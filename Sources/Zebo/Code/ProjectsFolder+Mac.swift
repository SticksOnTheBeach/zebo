import Foundation
import ZeboCore

extension ProjectsFolder {
    /// Le dossier de projets de ce Mac, deviné parmi les emplacements habituels.
    static func guessOnThisMac() -> URL? {
        guess(home: FileManager.default.homeDirectoryForCurrentUser) { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }

    /// Où créer les projets : le dossier choisi, sinon celui deviné, sinon « ~/Developer ».
    static func forNewProjects(_ preferences: ZeboPreferences) -> URL {
        preferences.projectsFolder.map { URL(fileURLWithPath: $0) }
            ?? guessOnThisMac()
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Developer")
    }
}
