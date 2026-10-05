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
                row(1, "curlybraces", .orange, "Ton langage", wizard.draft.favoriteLanguage?.name ?? "Aucun")
                divider
                row(
                    2, "chevron.left.forwardslash.chevron.right", .purple, "Tes éditeurs",
                    wizard.draft.ides.isEmpty ? "Aucun" : wizard.draft.ides.map(\.name).joined(separator: ", "))
                divider
                row(3, "rectangle.topthird.inset.filled", .teal, "Dans la notch", notchSummary)
                divider
                row(4, "moon.zzz.fill", .indigo, "La sieste", wizard.draft.sleepsWhenClosed ? "Oui" : "Non")
            }
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
        }
    }

    /// Les widgets choisis, et leur rythme s'ils défilent.
    private var notchSummary: String {
        let widgets = wizard.draft.displayableWidgets
        guard !widgets.isEmpty else { return "Rien" }
        let names = widgets.map(\.shortTitle).joined(separator: ", ")
        guard widgets.count > 1 else { return names }
        return names + " · toutes les \(Int(wizard.draft.widgetRotationInterval)) s"
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
