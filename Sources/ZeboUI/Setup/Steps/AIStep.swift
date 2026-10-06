import SwiftUI
import ZeboCore

/// Étape facultative : brancher Zebo sur Claude avec une clé d'API, pour qu'il repère tout seul
/// les workspaces quand on crée un projet.
struct AIStep: View {
    @Bindable var wizard: SetupWizard

    @FocusState private var isFocused: Bool

    private static let consoleURL: URL? = URL(string: "https://console.anthropic.com/settings/keys")

    var body: some View {
        SetupStepLayout(
            title: "Connecte-moi à Claude",
            subtitle: "Avec une clé d'API, je trouve tout seul où ranger tes nouveaux projets. Facultatif."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                field
                    .appearing(order: 2)

                HStack(spacing: 16) {
                    if wizard.hasStoredAPIKey, wizard.apiKey.isEmpty {
                        Label("Une clé est déjà enregistrée", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                    if let url = Self.consoleURL {
                        Link(destination: url) {
                            Label("Créer une clé sur la console Anthropic", systemImage: "arrow.up.right.square")
                        }
                        .foregroundStyle(ZeboPalette.cloudBottom)
                    }
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .appearing(order: 3)

                privacy
                    .appearing(order: 4)
            }
        }
    }

    private var field: some View {
        SecureField(
            "", text: $wizard.apiKey,
            prompt: Text(wizard.hasStoredAPIKey ? "Remplacer la clé (facultatif)" : "sk-ant-…")
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
                    "Je n'envoie à Claude que le nom de tes dossiers de projets et le nombre de fichiers de chaque type, jamais leur contenu. Ta clé reste dans le trousseau de ton Mac."
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
