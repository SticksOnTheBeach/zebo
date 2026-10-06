import SwiftUI

/// Première étape, façon Alcove : Zebo en grand au-dessus de son nom, une phrase,
/// trois façons de le retrouver dans une carte en colonnes, puis « Commencer ».
struct WelcomeStep: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // La place de Zebo, dessiné par la fenêtre au-dessus des étapes.
            Color.clear
                .frame(height: SetupWindowLayout.welcomeZeboFrame.maxY - 4)

            Text("Zebo")
                .font(.system(size: 68, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                .appearing(order: 0)

            Text(
                "Un petit nuage qui s'installe dans ta notch\net qui t'aide dans tous tes projets, du premier fichier au dernier commit."
            )
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.85))
            .lineSpacing(3)
            .padding(.top, 10)
            .appearing(order: 1)

            tips
                .padding(.top, 26)
                .appearing(order: 2)

            Text("C'est une toute nouvelle façon de vivre ton \u{F8FF} Mac.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 26)
                .appearing(order: 3)

            Button("Commencer", action: onStart)
                .buttonStyle(ZeboButtonStyle(shape: .wide))
                .keyboardShortcut(.defaultAction)
                .padding(.top, 18)
                .appearing(order: 4)

            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Trois façons de retrouver Zebo, en colonnes séparées par un trait fin.
    private var tips: some View {
        HStack(spacing: 0) {
            tip("cursorarrow.motionlines", .cyan, "Survole la notch\npour me réveiller")
            divider
            tip("cursorarrow.click.2", .pink, "Clique dessus\npour l'ouvrir")
            divider
            tip("folder.badge.plus", .indigo, "Je crée tes projets\net je les range pour toi")
        }
        .padding(.vertical, 18)
        .frame(width: 470)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.08)))
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 58)
    }

    private func tip(_ symbol: String, _ color: Color, _ text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white, color)
                .symbolRenderingMode(.palette)
                .frame(height: 26)
            Text(text)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
