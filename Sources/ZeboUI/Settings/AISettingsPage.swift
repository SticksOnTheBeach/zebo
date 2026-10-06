import SwiftUI
import ZeboCore

/// La section IA : le même écran que la configuration, plus le modèle et la clé à enregistrer.
struct AISettingsPage: View {
    @Bindable var wizard: SetupWizard
    let actions: SettingsView.Actions

    @State private var message: (text: String, isError: Bool)?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AIStep(wizard: wizard)

            if let provider = wizard.draft.aiProvider {
                controls(for: provider)
                    .padding(.horizontal, SetupWindowLayout.zeboFrame.minX)
                    .padding(.bottom, 28)
                    .appearing(order: 9)
            }
        }
        .animation(.easeOut(duration: 0.2), value: message?.text)
    }

    private func controls(for provider: AIProvider) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Modèle")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                TextField(
                    "", text: modelBinding(for: provider),
                    prompt: Text(provider.defaultModel).foregroundStyle(.white.opacity(0.3))
                )
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 240)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.black.opacity(0.25)))

                Spacer()

                if wizard.hasStoredAPIKey {
                    Button("Supprimer la clé") {
                        actions.deleteKey(provider)
                        wizard.providersWithStoredKey.remove(provider)
                        message = ("Clé \(provider.name) supprimée.", false)
                    }
                    .buttonStyle(ZeboButtonStyle())
                }
                Button("Enregistrer la clé") { save(for: provider) }
                    .buttonStyle(ZeboButtonStyle(kind: .primary))
                    .disabled(wizard.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let message {
                Text(message.text)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(message.isError ? .orange : .green)
            }
        }
    }

    private func modelBinding(for provider: AIProvider) -> Binding<String> {
        Binding(
            get: { wizard.draft.aiModels[provider.rawValue] ?? "" },
            set: { wizard.draft.setModel($0, for: provider) })
    }

    private func save(for provider: AIProvider) {
        let key = wizard.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if let problem = actions.saveKey(key, provider) {
            message = (problem, true)
        } else {
            wizard.providersWithStoredKey.insert(provider)
            wizard.apiKey = ""
            message = ("Clé \(provider.name) enregistrée dans le trousseau.", false)
        }
    }
}
