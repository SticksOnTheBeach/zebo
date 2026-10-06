import AppKit
import SwiftUI
import ZeboCore

/// Troisième étape : où ranger le projet. Zebo cherche les workspaces du genre choisi (avec Claude
/// si possible) et demande si on veut s'en servir, ou en créer un nouveau.
struct WorkspaceStep: View {
    @Bindable var wizard: NewProjectWizard

    /// Au-delà, la liste déborderait : les plus probables passent devant.
    private static let maxShown = 3

    var body: some View {
        SetupStepLayout(title: "Où je le range ?", subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 10) {
                switch wizard.search {
                case .idle, .searching:
                    searching
                        .transition(.opacity)
                case .done(let advice):
                    header(advice)
                        .appearing(order: 2)
                    ForEach(Array(advice.workspaces.prefix(Self.maxShown).enumerated()), id: \.element.path) {
                        index, suggestion in
                        existingCard(suggestion)
                            .appearing(order: 3 + index)
                    }
                    newWorkspaceCard
                        .appearing(order: 3 + min(advice.workspaces.count, Self.maxShown))
                    if wizard.isProjectFolderTaken {
                        Label(
                            "Un dossier « \(ProjectScaffolder.folderName(for: wizard.name)) » existe déjà ici.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: wizard.search)
        }
        .task { await wizard.searchWorkspaces() }
    }

    private var kindName: String { wizard.kind?.name ?? "" }

    private var subtitle: String {
        switch wizard.search {
        case .idle, .searching: "Je cherche tes workspaces \(kindName)…"
        case .done(let advice):
            advice.workspaces.isEmpty
                ? "Aucun workspace \(kindName) pour l'instant : je t'en prépare un."
                : "J'ai trouvé où tu ranges tes projets \(kindName). On le met dedans ?"
        }
    }

    // MARK: - Recherche

    private var searching: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            VStack(alignment: .leading, spacing: 2) {
                Text("Je regarde tes dossiers de projets…")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(abbreviated(wizard.projectsFolder.path))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card(isSelected: false))
    }

    private func header(_ advice: WorkspaceAdvice) -> some View {
        HStack(spacing: 6) {
            Image(systemName: advice.source == .ai ? "sparkles" : "magnifyingglass")
            Text(advice.source == .ai ? "Repéré par Claude" : "Repéré sans IA (noms de dossiers et fichiers)")
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(advice.source == .ai ? ZeboPalette.cloudBottom : .white.opacity(0.55))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white.opacity(0.08)))
    }

    // MARK: - Cartes

    private func existingCard(_ suggestion: WorkspaceSuggestion) -> some View {
        let isSelected = wizard.workspace == .existing(path: suggestion.path)
        return OptionCard(
            symbol: "folder.fill", color: .blue, isSelected: isSelected,
            title: (suggestion.path as NSString).lastPathComponent,
            path: abbreviated(suggestion.path), detail: suggestion.reason
        ) {
            wizard.workspace = .existing(path: suggestion.path)
        }
    }

    private var newWorkspaceCard: some View {
        let path = newWorkspacePath
        let isSelected = { if case .new = wizard.workspace { true } else { false } }()
        return OptionCard(
            symbol: "folder.badge.plus", color: .green, isSelected: isSelected,
            title: "Nouveau workspace", path: path.map(abbreviated) ?? "",
            detail: "Je crée ce dossier avec ton projet dedans."
        ) {
            if let path { wizard.workspace = .new(path: path) }
        } accessory: {
            Button("Ailleurs…", action: pickFolder)
                .buttonStyle(ZeboButtonStyle())
                .controlSize(.small)
        }
    }

    /// Le nouveau workspace choisi à la main, sinon celui que Zebo propose.
    private var newWorkspacePath: String? {
        if case .new(let path) = wizard.workspace { return path }
        return wizard.suggestedNewWorkspace
    }

    private func card(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.white.opacity(isSelected ? 0.12 : 0.05))
    }

    // MARK: - Actions

    /// Choisir un autre dossier : un dossier existant devient le workspace, sinon on le crée.
    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.title = "Où ranger tes projets \(kindName) ?"
        panel.prompt = "Choisir"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = wizard.projectsFolder
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            wizard.workspace = .existing(path: url.path)
        }
    }

    private func abbreviated(_ path: String) -> String {
        (path as NSString).abbreviatingWithTildeInPath
    }
}

/// Une option qu'on choisit d'un clic : un dossier, son chemin et pourquoi.
private struct OptionCard<Accessory: View>: View {
    let symbol: String
    let color: Color
    let isSelected: Bool
    let title: String
    let path: String
    let detail: String
    let onSelect: () -> Void
    @ViewBuilder var accessory: Accessory

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 15))
                .foregroundStyle(isSelected ? ZeboPalette.cloudBottom : .white.opacity(0.35))
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Text(detail)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(isSelected ? 0.12 : (isHovered ? 0.08 : 0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? ZeboPalette.cloudBottom.opacity(0.8) : .white.opacity(0.07))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { onSelect() }
        }
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

extension OptionCard where Accessory == EmptyView {
    init(
        symbol: String, color: Color, isSelected: Bool, title: String, path: String, detail: String,
        onSelect: @escaping () -> Void
    ) {
        self.init(
            symbol: symbol, color: color, isSelected: isSelected, title: title, path: path, detail: detail,
            onSelect: onSelect, accessory: { EmptyView() })
    }
}
