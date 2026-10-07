import SwiftUI

/// La section Avancé : refaire la configuration, quitter, et (en développement) tout effacer.
struct AdvancedSettingsPage: View {
    let actions: SettingsView.Actions

    var body: some View {
        SetupStepLayout(title: "Avancé", subtitle: "Pour repartir du bon pied, ou me laisser me reposer.") {
            SettingsGroup {
                SettingsRow(
                    symbol: "arrow.counterclockwise", color: .blue, title: "Refaire la configuration",
                    detail: "La fenêtre de bienvenue, avec tes réglages actuels."
                ) {
                    Button("Lancer", action: actions.reconfigure)
                        .buttonStyle(ZeboButtonStyle())
                }
                SettingsDivider()
                SettingsRow(
                    symbol: "power", color: .red, title: "Quitter Zebo",
                    detail: "Je disparais de ta notch jusqu'au prochain lancement."
                ) {
                    Button("Quitter", action: actions.quit)
                        .buttonStyle(ZeboButtonStyle())
                }
                if let reset = actions.reset {
                    SettingsDivider()
                    SettingsRow(
                        symbol: "trash.fill", color: .orange, title: "Réinitialiser Zebo",
                        detail: "Développement : efface tout et me relance comme au premier jour."
                    ) {
                        Button("Effacer", action: reset)
                            .buttonStyle(ZeboButtonStyle())
                    }
                }
            }
            .appearing(order: 2)
        }
    }
}
