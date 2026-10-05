import SwiftUI

/// Première étape : Zebo se présente.
struct WelcomeStep: View {
    var body: some View {
        SetupStepLayout(
            title: "Salut ! Moi c'est Zebo.",
            subtitle: "Un petit nuage qui vient habiter ta notch."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                feature(
                    "rectangle.topthird.inset.filled", .blue, "Je vis dans ta notch",
                    "Passe la souris dessus : elle s'ouvre et je me réveille.", order: 2)
                feature(
                    "bubble.left.and.bubble.right.fill", .pink, "Je te tiens compagnie",
                    "Clique sur moi et je te dirai un petit mot.", order: 3)
                feature(
                    "moon.zzz.fill", .indigo, "Je fais la sieste",
                    "Quand tu travailles, je dors dans mon lit, sans te déranger.", order: 4)
            }
        }
    }

    private func feature(
        _ symbol: String, _ color: Color, _ title: String, _ detail: String, order: Int
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .appearing(order: order)
    }
}
