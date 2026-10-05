import SwiftUI

/// Contenu de la fenêtre de configuration : Zebo en haut à gauche, et son message d'accueil.
public struct SetupView: View {
    @State private var showsGreeting = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black

            // Il regarde droit devant, cligne des yeux et se balance doucement.
            AnimatedZebo(mouse: .zero, center: .zero, isAwake: true)
                .frame(width: zebo.width, height: zebo.height)
                .offset(x: zebo.minX, y: zebo.minY)

            greeting
                .opacity(showsGreeting ? 1 : 0)
                .offset(y: showsGreeting ? 0 : 8)
        }
        .frame(width: SetupWindowLayout.size.width, height: SetupWindowLayout.size.height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) { showsGreeting = true }
        }
    }

    private var zebo: CGRect { SetupWindowLayout.zeboFrame }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Le titre, à droite de Zebo et centré sur lui.
            Text("Salut ! Moi c'est Zebo.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(height: zebo.height)
                .padding(.leading, zebo.maxX + 20)
                .padding(.top, zebo.minY)

            Text(
                """
                Je vais m'installer dans ta notch et te tenir compagnie pendant que tu travailles.
                Avant ça, j'aimerais apprendre à te connaître : quelques questions, et c'est parti !
                """
            )
            .font(.system(size: 15, design: .rounded))
            .lineSpacing(4)
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: SetupWindowLayout.size.width - zebo.minX * 2, alignment: .leading)
            .padding(.leading, zebo.minX)
            .padding(.top, 28)
        }
    }
}
