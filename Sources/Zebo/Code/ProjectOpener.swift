import AppKit
import ZeboCore

/// Ouvre un projet dans un éditeur, le Finder ou le Terminal.
enum ProjectOpener {
    /// Avec son éditeur habituel s'il en a un, sinon dans le Finder.
    @MainActor
    static func open(_ project: ZeboProject) {
        open(project, with: project.editor.map(ProjectOpenTarget.editor) ?? .finder)
    }

    @MainActor
    static func open(_ project: ZeboProject, with target: ProjectOpenTarget) {
        let folder = URL(fileURLWithPath: project.path)
        switch target {
        case .editor(let editor):
            openFolder(folder, withApplicationAt: URL(fileURLWithPath: editor.path))
        case .finder:
            NSWorkspace.shared.activateFileViewerSelecting([folder])
        case .terminal:
            // Terminal ouvre un dossier en s'y plaçant.
            if let terminal = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
                openFolder(folder, withApplicationAt: terminal)
            }
        }
    }

    @MainActor
    private static func openFolder(_ folder: URL, withApplicationAt application: URL) {
        NSWorkspace.shared.open(
            [folder], withApplicationAt: application, configuration: NSWorkspace.OpenConfiguration())
    }
}
