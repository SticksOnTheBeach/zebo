import SwiftUI
import ZeboCore

/// Étape facultative : brancher Zebo sur une IA (Claude, ChatGPT, Gemini, Mistral) avec une clé
/// d'API, pour qu'il repère tout seul les workspaces quand on crée un projet.
struct AIStep: View {
    @Bindable var wizard: SetupWizard

    @FocusState private var isFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        SetupStepLayout(
            title: "Connecte-moi à une IA",
            subtitle: "Avec une clé d'API, je trouve tout seul où ranger tes nouveaux projets. Facultatif."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(AIProvider.allCases.enumerated()), id: \.element) { index, provider in
                        providerTile(provider)
                            .appearing(order: 2 + index)
                    }
                    SelectableTile(title: "Aucune", isSelected: wizard.draft.aiProvider == nil) {
                        select(nil)
                    } icon: {
                        Image(systemName: "nosign")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .appearing(order: 6)
                }

                if let provider = wizard.draft.aiProvider {
                    field(for: provider)
                        .appearing(order: 7)

                    HStack(spacing: 16) {
                        if wizard.hasStoredAPIKey, wizard.apiKey.isEmpty {
                            Label("Une clé \(provider.name) est déjà enregistrée", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                        if let url = provider.keysPage {
                            Link(destination: url) {
                                Label("Créer une clé chez \(provider.company)", systemImage: "arrow.up.right.square")
                            }
                            .foregroundStyle(ZeboPalette.cloudBottom)
                        }
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                }

                privacy
                    .appearing(order: 8)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: wizard.draft.aiProvider)
        }
    }

    private func providerTile(_ provider: AIProvider) -> some View {
        SelectableTile(title: provider.name, isSelected: wizard.draft.aiProvider == provider) {
            select(provider)
        } icon: {
            AIProviderBadge(provider: provider)
        }
    }

    /// Changer d'IA oublie la clé tapée pour la précédente.
    private func select(_ provider: AIProvider?) {
        guard wizard.draft.aiProvider != provider else { return }
        wizard.apiKey = ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { wizard.draft.aiProvider = provider }
    }

    private func field(for provider: AIProvider) -> some View {
        SecureField(
            "", text: $wizard.apiKey,
            prompt: Text(wizard.hasStoredAPIKey ? "Remplacer la clé (facultatif)" : provider.keyPlaceholder)
                .foregroundStyle(.white.opacity(0.3))
        )
        .textFieldStyle(.plain)
        .font(.system(size: 18, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .focused($isFocused)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 460)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.25)))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFocused ? ZeboPalette.cloudBottom : .white.opacity(0.1), lineWidth: isFocused ? 2 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }

    /// Ce que Zebo envoie, et ce qu'il garde pour lui.
    private var privacy: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white, .blue)
                .symbolRenderingMode(.palette)
            VStack(alignment: .leading, spacing: 4) {
                Text("Confidentialité")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(
                    "Je n'envoie à l'IA que le nom de tes dossiers de projets et le nombre de fichiers de chaque type, jamais leur contenu. Ta clé reste dans le trousseau de ton Mac."
                )
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.08)))
    }
}
