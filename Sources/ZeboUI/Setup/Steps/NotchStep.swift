import SwiftUI
import ZeboCore

/// Quatrième étape : ce qu'affiche la notch fermée, avec un aperçu qui suit les réglages.
struct NotchStep: View {
    @Bindable var wizard: SetupWizard

    var body: some View {
        SetupStepLayout(
            title: "Et ma notch ?",
            subtitle: "Quand elle est fermée, voici ce qu'on y voit."
        ) {
            VStack(spacing: 16) {
                NotchPreview(showsClock: wizard.draft.shows(.clock), sleeps: wizard.draft.sleepsWhenClosed)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: wizard.draft)
                    .appearing(order: 2)

                VStack(spacing: 0) {
                    ToggleRow(
                        symbol: "clock.fill", color: .blue, title: "Afficher l'heure",
                        detail: "Dans l'aile droite de la notch.",
                        isOn: Binding(
                            get: { wizard.draft.shows(.clock) },
                            set: { wizard.draft.setWidget(.clock, shown: $0) }))
                    Divider()
                        .overlay(.white.opacity(0.06))
                        .padding(.leading, 60)
                    ToggleRow(
                        symbol: "moon.zzz.fill", color: .indigo, title: "Faire la sieste",
                        detail: "Je dors dans mon lit quand la notch est fermée.",
                        isOn: $wizard.draft.sleepsWhenClosed)
                }
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
                .appearing(order: 3)
            }
        }
    }
}

/// Une ligne de réglage façon Réglages Système : icône colorée, titre, détail, interrupteur.
private struct ToggleRow: View {
    let symbol: String
    let color: Color
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Toggle("", isOn: $isOn.animation(.spring(response: 0.45, dampingFraction: 0.8)))
                .toggleStyle(.switch)
                .tint(ZeboPalette.cloudBottom)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
