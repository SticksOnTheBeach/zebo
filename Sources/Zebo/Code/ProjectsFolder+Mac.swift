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
}
