import AppKit
import SwiftUI
import ZeboCore

/// L'onglet Projets de la notch ouverte : les derniers projets créés avec Zebo et le bouton pour en
/// créer un nouveau. Un clic sur un projet le déplie : on choisit avec quoi l'ouvrir
/// (un de ses éditeurs, le Finder ou le Terminal).
struct ProjectsTabView: View {
    let library: ProjectsLibrary
    /// Les éditeurs choisis pendant la configuration.
    let editors: [IDEChoice]
    let onOpen: (ZeboProject, ProjectOpenTarget) -> Void
    let onNewProject: () -> Void

    /// Le projet déplié, s'il y en a un.
    @State private var expanded: ZeboProject.ID?

    /// La notch est petite : les plus récents seulement.
    private static let maxShown = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(library.projects.isEmpty ? "Aucun projet" : "Récents")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                Spacer()
                Button(action: onNewProject) {
                    Label("Nouveau", systemImage: "plus")
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(ZeboButtonStyle())
            }

            if library.projects.isEmpty {
                Text("Je t'aide à le créer et à le ranger au bon endroit.")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            ForEach(library.projects.prefix(Self.maxShown)) { project in
                ProjectRow(project: project, editors: editors, isExpanded: expanded == project.id) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        expanded = expanded == project.id ? nil : project.id
                    }
                } onOpen: { target in
                    onOpen(project, target)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { expanded = nil }
                }
            }
        }
    }
}

/// Un projet : son logo, son nom et son dossier. Déplié, la rangée « Ouvrir avec ».
private struct ProjectRow: View {
    let project: ZeboProject
    let editors: [IDEChoice]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onOpen: (ProjectOpenTarget) -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if isExpanded {
                openWith
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(isExpanded ? 0.1 : (isHovered ? 0.07 : 0)))
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var header: some View {
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
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(isHovered || isExpanded ? 0.8 : 0.3))
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }

    /// Ses éditeurs (l'habituel en premier), puis le Finder et le Terminal.
    private var openWith: some View {
        HStack(spacing: 6) {
            Text("Ouvrir avec")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            ForEach(orderedEditors, id: \.path) { editor in
                OpenWithButton(
                    icon: NSWorkspace.shared.icon(forFile: editor.path), help: editor.name,
                    isUsual: editor == project.editor
                ) { onOpen(.editor(editor)) }
            }
            OpenWithButton(
                icon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"), help: "Le Finder",
                isUsual: false
            ) { onOpen(.finder) }
            if let terminal = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
                OpenWithButton(
                    icon: NSWorkspace.shared.icon(forFile: terminal.path), help: "Le Terminal", isUsual: false
                ) { onOpen(.terminal) }
            }
        }
        .padding(.leading, 24)
    }

    private var orderedEditors: [IDEChoice] {
        var list = editors
        if let usual = project.editor {
            list.removeAll { $0.path == usual.path }
            list.insert(usual, at: 0)
        }
        return list
    }
}

/// Une icône d'app sur laquelle on clique pour ouvrir le projet ; l'habituelle a un petit point.
private struct OpenWithButton: View {
    let icon: NSImage
    let help: String
    let isUsual: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .frame(width: 20, height: 20)
            .scaleEffect(isHovered ? 1.2 : 1)
            .overlay(alignment: .bottom) {
                if isUsual {
                    Circle()
                        .fill(ZeboPalette.cloudBottom)
                        .frame(width: 4, height: 4)
                        .offset(y: 5)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .onHover { isHovered = $0 }
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHovered)
            .help("Ouvrir avec \(help)")
    }
}
