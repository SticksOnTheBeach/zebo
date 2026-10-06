import AppKit
import SwiftUI
import ZeboCore

/// L'onglet Projets de la notch ouverte : les derniers projets créés avec Zebo (un clic propose
/// de les ouvrir avec un éditeur, le Finder ou le Terminal) et le bouton pour en créer un nouveau.
struct ProjectsTabView: View {
    let library: ProjectsLibrary
    /// Les éditeurs choisis pendant la configuration.
    let editors: [IDEChoice]
    let onOpen: (ZeboProject, ProjectOpenTarget) -> Void
    let onNewProject: () -> Void

    /// La notch est petite : les plus récents seulement.
    private static let maxShown = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if library.projects.isEmpty {
                Text("Aucun projet pour l'instant.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Je t'aide à le créer et à le ranger au bon endroit.")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ForEach(library.projects.prefix(Self.maxShown)) { project in
                    ProjectRow(project: project, editors: editors) { onOpen(project, $0) }
                }
            }

            Button(action: onNewProject) {
                Label("Nouveau projet", systemImage: "plus")
            }
            .buttonStyle(ZeboButtonStyle())
            .padding(.top, 2)
        }
    }
}

/// Un projet : son logo, son nom et son dossier. Un clic propose de l'ouvrir avec un de tes
/// éditeurs (le dernier utilisé en premier), le Finder ou le Terminal.
private struct ProjectRow: View {
    let project: ZeboProject
    let editors: [IDEChoice]
    let onOpen: (ProjectOpenTarget) -> Void

    @State private var isHovered = false

    var body: some View {
        Menu {
            Section("Ouvrir « \(project.name) » avec") {
                ForEach(orderedEditors, id: \.path) { editor in
                    Button {
                        onOpen(.editor(editor))
                    } label: {
                        Label {
                            Text(editor == project.editor ? "\(editor.name)  ✓" : editor.name)
                        } icon: {
                            Image(nsImage: Self.menuIcon(forFile: editor.path))
                        }
                    }
                }
            }
            Divider()
            Button {
                onOpen(.finder)
            } label: {
                Label("Le Finder", systemImage: "folder")
            }
            Button {
                onOpen(.terminal)
            } label: {
                Label("Le Terminal", systemImage: "terminal")
            }
        } label: {
            label
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var label: some View {
        HStack(spacing: 8) {
            CodeLogo(kind: project.kind, size: 16)
            Text(project.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(((project.path as NSString).deletingLastPathComponent as NSString).abbreviatingWithTildeInPath)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(isHovered ? 0.8 : 0.3))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.white.opacity(isHovered ? 0.1 : 0)))
        .contentShape(Rectangle())
    }

    /// L'éditeur habituel du projet d'abord, puis les autres.
    private var orderedEditors: [IDEChoice] {
        var list = editors
        if let usual = project.editor {
            list.removeAll { $0.path == usual.path }
            list.insert(usual, at: 0)
        }
        return list
    }

    /// L'icône d'une app, à la taille d'une icône de menu.
    private static func menuIcon(forFile path: String) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }
}
