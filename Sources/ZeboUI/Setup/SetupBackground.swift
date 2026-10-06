import SwiftUI

/// Le fond de la fenêtre de configuration : du noir, une lueur rose qui suit Zebo,
/// et une touche violette dans le coin, pour donner de la profondeur sans distraire.
struct SetupBackground: View {
    /// Centre de la lueur rose (là où est Zebo), dans la fenêtre.
    var glowCenter: CGPoint
    /// Taille de la lueur : plus grande quand Zebo est en grand.
    var glowSize: CGFloat

    /// La lueur s'allume doucement : la fenêtre arrive noire, comme la notch dont elle vient.
    @State private var isLit = false
    @Environment(\.showsFinalAppearance) private var showsFinalAppearance

    var body: some View {
        ZStack {
            Color.black

            Circle()
                .fill(ZeboPalette.cloudBottom.opacity(0.42))
                .frame(width: glowSize, height: glowSize)
                .blur(radius: glowSize * 0.35)
                .position(glowCenter)

            Circle()
                .fill(Color(red: 0.45, green: 0.36, blue: 0.95).opacity(0.3))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .position(x: SetupWindowLayout.size.width, y: SetupWindowLayout.size.height)
        }
        .opacity(isLit || showsFinalAppearance ? 1 : 0)
        .background(Color.black)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { isLit = true }
        }
        .allowsHitTesting(false)
    }
}
