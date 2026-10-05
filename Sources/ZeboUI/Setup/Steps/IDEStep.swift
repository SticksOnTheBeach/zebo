import AppKit
import SwiftUI
import UniformTypeIdentifiers
import ZeboCore

/// Étape de l'éditeur de code : on choisit le sien, Zebo retrouve tout seul où il est installé,
/// pour pouvoir le lancer plus tard.
struct IDEStep: View {
    @Bindable var wizard: SetupWizard

    /// L'éditeur que Zebo est en train de chercher.
    @State private var searching: IDE?
    /// Les éditeurs installés et leur emplacement (pour afficher leur icône).
    @State private var installed: [String: URL] = [:]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        SetupStepLayout(
            title: "Tu codes avec quoi ?",
            subtitle: "Choisis ton éditeur : je retrouve tout seul où il est installé."
        ) {
            VStack(spacing: 14) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(IDE.catalog.enumerated()), id: \.element) { index, ide in
                        IDETile(
                            ide: ide,
                            icon: installed[ide.id].map(Self.icon),
                            isSelected: wizard.draft.ide?.id == ide.id,
                            isSearching: searching == ide
                        ) { search(ide) }
                        // Les tuiles arrivent en vague, une colonne après l'autre.
                        .appearing(order: 2 + index % 6)
                    }
                }

                result
                    .frame(height: 56)
                    .appearing(order: 8)
            }
        }
        .onAppear {
            installed = Dictionary(
                uniqueKeysWithValues: IDE.catalog.compactMap { ide in
                    wizard.installedLocation(of: ide).map { (ide.id, $0) }
                })
        }
    }

    // MARK: - Recherche

    private func search(_ ide: IDE) {
        guard searching == nil else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { searching = ide }
        // Le temps de voir Zebo chercher : la recherche elle-même est instantanée.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                wizard.chooseIDE(ide)
                searching = nil
            }
        }
    }

    /// Choisir une app à la main, pour l'éditeur introuvable ou un autre.
    private func pickApplication(for ide: IDE?) {
        let panel = NSOpenPanel()
        panel.title = ide.map { "Où est \($0.name) ?" } ?? "Choisis ton éditeur"
        panel.prompt = "Choisir"
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                wizard.chooseApplication(at: url, as: ide)
            }
        }
    }

    // MARK: - Résultat

    @ViewBuilder
    private var result: some View {
        Group {
            if let searching {
                ResultCard {
                    ProgressView().controlSize(.small)
                } text: {
                    Text("Je cherche \(searching.name)…")
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else {
                switch wizard.ideSearch {
                case .found(let choice):
                    ResultCard {
                        Image(nsImage: Self.icon(URL(fileURLWithPath: choice.path)))
                            .resizable()
                            .frame(width: 30, height: 30)
                    } text: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Trouvé : \(choice.name)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(choice.path)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    } action: {
                        Button("Changer…") { pickApplication(for: nil) }
                            .buttonStyle(ZeboButtonStyle())
                    }
                case .notFound(let ide):
                    ResultCard {
                        Image(systemName: "questionmark.folder.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.orange)
                    } text: {
                        Text("Je ne trouve pas \(ide.name) sur ce Mac.")
                            .foregroundStyle(.white.opacity(0.8))
                    } action: {
                        Button("Le chercher moi-même…") { pickApplication(for: ide) }
                            .buttonStyle(ZeboButtonStyle())
                    }
                case .none:
                    ResultCard {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    } text: {
                        Text("Pas dans la liste ? Tu peux aussi passer cette étape.")
                            .foregroundStyle(.white.opacity(0.6))
                    } action: {
                        Button("Autre…") { pickApplication(for: nil) }
                            .buttonStyle(ZeboButtonStyle())
                    }
                }
            }
        }
        .font(.system(size: 13, design: .rounded))
        .transition(.opacity.combined(with: .offset(y: 6)))
    }

    private static func icon(_ url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

/// La carte sous la grille : une icône, un texte, et parfois un bouton.
private struct ResultCard<Icon: View, Label: View, Action: View>: View {
    @ViewBuilder var icon: Icon
    @ViewBuilder var text: Label
    @ViewBuilder var action: Action

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 30, height: 30)
            text
            Spacer(minLength: 8)
            action
        }
        .padding(.horizontal, 14)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
    }
}

extension ResultCard where Action == EmptyView {
    init(@ViewBuilder icon: () -> Icon, @ViewBuilder text: () -> Label) {
        self.init(icon: icon, text: text, action: { EmptyView() })
    }
}

/// Une tuile d'éditeur : sa vraie icône s'il est installé, sinon ses initiales, en plus discret.
private struct IDETile: View {
    let ide: IDE
    let icon: NSImage?
    let isSelected: Bool
    let isSearching: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let icon {
                    Image(nsImage: icon)
                        .resizable()
                } else {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(white: 0.2))
                        .overlay(
                            Text(initials)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        )
                        .padding(3)
                }
            }
            .frame(width: 38, height: 38)
            .scaleEffect(isSearching ? 1.12 : 1)

            Text(ide.name)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .opacity(icon == nil && !isSelected ? 0.45 : 1)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: isSelected ? 0.17 : (isHovered ? 0.12 : 0.08)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isSelected ? ZeboPalette.cloudBottom : .white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(ZeboPalette.cloudBottom)
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isHovered && !isSelected ? 1.04 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSearching)
    }

    private var initials: String {
        ide.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}
