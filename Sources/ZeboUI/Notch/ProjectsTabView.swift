import SwiftUI
import ZeboCore

/// L'onglet Projets de la notch ouverte : les derniers projets créés avec Zebo (un clic les ouvre)
/// et le bouton pour en créer un nouveau.
struct ProjectsTabView: View {
    let library: ProjectsLibrary
    let onOpen: (ZeboProject) -> Void
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
                    ProjectRow(project: project) { onOpen(project) }
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

/// Un projet : son logo, son nom et son dossier ; s'éclaire au survol, s'ouvre au clic.
private struct ProjectRow: View {
    let project: ZeboProject
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            CodeLogo(kind: project.kind, size: 16)
            Text(project.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text((project.path as NSString).deletingLastPathComponent.abbreviatedPath)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            Image(systemName: "arrow.up.forward.app")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(isHovered ? 0.8 : 0.3))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.white.opacity(isHovered ? 0.1 : 0)))
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .help(project.editor.map { "Ouvrir dans \($0.name)" } ?? "Ouvrir dans le Finder")
    }
}

extension String {
    fileprivate var abbreviatedPath: String { (self as NSString).abbreviatingWithTildeInPath }
}
