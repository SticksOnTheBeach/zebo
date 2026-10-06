import SwiftUI

/// La section Avancé : refaire la configuration, quitter, et (en développement) tout effacer.
struct AdvancedSettingsPage: View {
    let actions: SettingsView.Actions

    var body: some View {
        SetupStepLayout(title: "Avancé", subtitle: "Pour repartir du bon pied, ou me laisser me reposer.") {
            VStack(spacing: 0) {
                row(
                    "arrow.counterclockwise", .blue, "Refaire la configuration",
                    "La fenêtre de bienvenue, avec tes réglages actuels.", button: "Lancer", action: actions.reconfigure
                )
                divider
                row(
                    "power", .red, "Quitter Zebo", "Je disparais de ta notch jusqu'au prochain lancement.",
                    button: "Quitter", action: actions.quit)
                if let reset = actions.reset {
                    divider
                    row(
                        "trash.fill", .orange, "Réinitialiser Zebo",
                        "Développement : efface tout et me relance comme au premier jour.", button: "Effacer",
                        action: reset)
                }
            }
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
            .appearing(order: 2)
        }
    }

    private var divider: some View {
        Divider()
            .overlay(.white.opacity(0.06))
            .padding(.leading, 58)
    }

    private func row(
        _ symbol: String, _ color: Color, _ title: String, _ detail: String, button: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button(button, action: action)
                .buttonStyle(ZeboButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
