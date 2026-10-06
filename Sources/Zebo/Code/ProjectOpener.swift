import AppKit
import ZeboCore

/// Ouvre un projet : dans son éditeur s'il en a un, sinon dans le Finder.
enum ProjectOpener {
    @MainActor
    static func open(_ project: ZeboProject) {
        let folder = URL(fileURLWithPath: project.path)
        guard let editor = project.editor else {
            NSWorkspace.shared.activateFileViewerSelecting([folder])
            return
        }
        NSWorkspace.shared.open(
            [folder], withApplicationAt: URL(fileURLWithPath: editor.path),
            configuration: NSWorkspace.OpenConfiguration())
    }
}
