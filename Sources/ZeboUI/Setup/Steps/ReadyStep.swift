import SwiftUI
import ZeboCore

/// Dernière étape : le récapitulatif, avant que Zebo file s'installer dans la notch.
struct ReadyStep: View {
    let wizard: SetupWizard

    var body: some View {
        SetupStepLayout(
            title: "Tout est prêt, \(wizard.trimmedName) !",
            subtitle: "Je file m'installer dans ta notch. Passe la souris dessus pour me voir."
        ) {
            VStack(spacing: 0) {
                row(0, "person.fill", .blue, "Je t'appelle", wizard.trimmedName)
                divider
                row(
                    1, wizard.draft.personality.symbol, wizard.draft.personality.color, "Ma personnalité",
                    wizard.draft.personality.title)
                divider
                row(
                    2, "chevron.left.forwardslash.chevron.right", .purple, "Ton éditeur",
                    wizard.draft.ide?.name ?? "Aucun")
                divider
                row(3, "clock.fill", .teal, "L'heure dans la notch", wizard.draft.showsClock ? "Oui" : "Non")
                divider
                row(4, "moon.zzz.fill", .indigo, "La sieste", wizard.draft.sleepsWhenClosed ? "Oui" : "Non")
            }
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
        }
    }

    private var divider: some View {
        Divider()
            .overlay(.white.opacity(0.06))
            .padding(.leading, 60)
    }

    private func row(_ index: Int, _ symbol: String, _ color: Color, _ label: String, _ value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.gradient))
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .appearing(order: 2 + index)
    }
}
