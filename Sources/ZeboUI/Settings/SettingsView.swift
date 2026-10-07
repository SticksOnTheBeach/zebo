import SwiftUI
import ZeboCore

/// La fenêtre de paramètres de Zebo : une barre latérale façon Réglages Système, et à droite les
/// mêmes écrans que la configuration. Chaque changement s'applique tout de suite.
public struct SettingsView: View {
    /// Ce que la fenêtre demande à l'app.
    public struct Actions {
        /// Les préférences ont changé : les enregistrer et les appliquer.
        public var preferencesDidChange: (ZeboPreferences) -> Void
        /// Ranger une clé d'API dans le trousseau (renvoie le problème, s'il y en a un).
        public var saveKey: (String, AIProvider) -> String?
        public var deleteKey: (AIProvider) -> Void
        /// Refaire la configuration depuis le début (fenêtre de bienvenue).
        public var reconfigure: () -> Void
        public var quit: () -> Void
        /// Tout effacer (versions de développement seulement).
        public var reset: (() -> Void)?

        public init(
            preferencesDidChange: @escaping (ZeboPreferences) -> Void,
            saveKey: @escaping (String, AIProvider) -> String?, deleteKey: @escaping (AIProvider) -> Void,
            reconfigure: @escaping () -> Void, quit: @escaping () -> Void, reset: (() -> Void)?
        ) {
            self.preferencesDidChange = preferencesDidChange
            self.saveKey = saveKey
            self.deleteKey = deleteKey
            self.reconfigure = reconfigure
            self.quit = quit
            self.reset = reset
        }
    }

    public static let size = CGSize(width: SetupWindowLayout.size.width + Self.sidebarWidth, height: 600)
    static let sidebarWidth: CGFloat = 220

    /// Les réglages en cours d'édition (le même modèle que la configuration).
    private let wizard: SetupWizard
    private let commits: CommitActivity
    private let actions: Actions

    @State private var section: SettingsSection = .general
    @State private var previousSection: SettingsSection = .general

    public init(wizard: SetupWizard, commits: CommitActivity, actions: Actions) {
        self.wizard = wizard
        self.commits = commits
        self.actions = actions
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(.white.opacity(0.08))
            content
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            SetupBackground(
                glowCenter: CGPoint(
                    x: Self.sidebarWidth + SetupWindowLayout.zeboFrame.midX, y: SetupWindowLayout.zeboFrame.midY),
                glowSize: 220)
        }
        .onChange(of: wizard.draft) { _, _ in actions.preferencesDidChange(wizard.preferences) }
    }

    // MARK: - Barre latérale

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Paramètres")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            ForEach(SettingsSection.allCases) { item in
                SidebarRow(section: item, isSelected: section == item) { select(item) }
            }
            Spacer()
        }
        .padding(.top, 44)
        .padding(.horizontal, 10)
        .frame(width: Self.sidebarWidth)
        .background(.black.opacity(0.18))
    }

    private func select(_ item: SettingsSection) {
        guard item != section else { return }
        previousSection = section
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { section = item }
    }

    // MARK: - Contenu

    private var content: some View {
        ZStack(alignment: .topLeading) {
            AnimatedZebo(mouse: CGPoint(x: 20, y: -100), center: .zero, isAwake: true, hopTrigger: sectionIndex)
                .frame(width: SetupWindowLayout.zeboFrame.width, height: SetupWindowLayout.zeboFrame.height)
                .offset(x: SetupWindowLayout.zeboFrame.minX, y: SetupWindowLayout.zeboFrame.minY)

            ZStack {
                page(section)
                    .id(section)
                    .transition(transition)
            }
        }
        .frame(width: SetupWindowLayout.size.width, height: Self.size.height, alignment: .topLeading)
        .clipped()
    }

    @ViewBuilder
    private func page(_ section: SettingsSection) -> some View {
        switch section {
        case .general: NameStep(wizard: wizard)
        case .language: LanguageStep(wizard: wizard)
        case .editors: IDEStep(wizard: wizard)
        case .notch: NotchStep(wizard: wizard, commits: commits)
        case .ai: AISettingsPage(wizard: wizard, actions: actions)
        case .permissions: PermissionsSettingsPage(wizard: wizard)
        case .advanced: AdvancedSettingsPage(actions: actions)
        }
    }

    private var sectionIndex: Int { SettingsSection.allCases.firstIndex(of: section) ?? 0 }

    /// La section arrive du bas si on descend dans la liste, du haut si on remonte.
    private var transition: AnyTransition {
        let order = SettingsSection.allCases
        let isGoingDown = (order.firstIndex(of: section) ?? 0) >= (order.firstIndex(of: previousSection) ?? 0)
        let shift: CGFloat = isGoingDown ? 40 : -40
        return .asymmetric(
            insertion: .offset(y: shift).combined(with: .opacity),
            removal: .offset(y: -shift).combined(with: .opacity))
    }
}

/// Une ligne de la barre latérale : icône colorée et nom, surlignée quand elle est choisie.
private struct SidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(section.color.gradient))
            Text(section.title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected ? 1 : 0.8))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(isSelected ? 0.14 : (isHovered ? 0.06 : 0)))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}
