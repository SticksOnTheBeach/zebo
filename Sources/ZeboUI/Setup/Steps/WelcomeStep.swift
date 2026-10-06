import SwiftUI

/// Première étape : Zebo, en grand au centre, se présente en trois cartes.
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 0) {
            // La place de Zebo, dessiné par la fenêtre au-dessus des étapes.
            Color.clear
                .frame(height: SetupWindowLayout.welcomeZeboFrame.maxY + 20)

            Text("Salut ! Moi c'est Zebo.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .appearing(order: 0)

            Text("Un petit nuage qui vient habiter ta notch.")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 8)
                .appearing(order: 1)

            HStack(alignment: .top, spacing: 12) {
                FeatureCard(
                    symbol: "rectangle.topthird.inset.filled", color: .blue, title: "Je vis dans ta notch",
                    detail: "Passe la souris dessus : elle s'ouvre et je me réveille."
                )
                .appearing(order: 2)
                FeatureCard(
                    symbol: "bubble.left.and.bubble.right.fill", color: .pink, title: "Je te tiens compagnie",
                    detail: "Clique sur moi et je te dirai un petit mot."
                )
                .appearing(order: 3)
                FeatureCard(
                    symbol: "moon.zzz.fill", color: .indigo, title: "Je fais la sieste",
                    detail: "Quand tu travailles, je dors dans mon lit, sans te déranger."
                )
                .appearing(order: 4)
            }
            .padding(.horizontal, SetupWindowLayout.zeboFrame.minX)
            .padding(.top, 30)

            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Une carte de présentation, translucide, avec une touche de lumière en haut.
private struct FeatureCard: View {
    let symbol: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.gradient))
                .shadow(color: color.opacity(0.5), radius: 10, y: 3)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 12.5, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.09), .white.opacity(0.03)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.09)))
    }
}
