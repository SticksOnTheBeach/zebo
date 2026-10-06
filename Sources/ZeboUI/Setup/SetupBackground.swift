import SwiftUI

/// Le fond de la fenêtre de configuration, façon Alcove : du verre dépoli, des lueurs colorées
/// floues (dont une rose qui suit Zebo) et de petites étincelles. La fenêtre arrive noire,
/// comme la notch dont elle vient, puis le verre se révèle.
struct SetupBackground: View {
    /// Centre de la lueur rose (là où est Zebo), dans la fenêtre.
    var glowCenter: CGPoint
    /// Taille de la lueur : plus grande quand Zebo est en grand.
    var glowSize: CGFloat

    @State private var isRevealed = false
    @Environment(\.showsFinalAppearance) private var showsFinalAppearance

    private var size: CGSize { SetupWindowLayout.size }

    var body: some View {
        ZStack {
            // Le verre ne se dessine pas hors écran (aperçus, captures) : un gris sombre le remplace.
            if showsFinalAppearance {
                Color(white: 0.16)
            } else {
                VisualEffectBackground()
            }
            // Assombri, pour que le texte reste lisible sur n'importe quel fond.
            Color.black.opacity(0.35)

            aurora

            Circle()
                .fill(ZeboPalette.cloudBottom.opacity(0.35))
                .frame(width: glowSize, height: glowSize)
                .blur(radius: glowSize * 0.35)
                .position(glowCenter)

            SparkleField()

            // Le noir de la notch, qui s'efface.
            Color.black
                .opacity(isRevealed || showsFinalAppearance ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { isRevealed = true }
        }
        .allowsHitTesting(false)
    }

    /// Des taches de couleur très floues, comme une aurore derrière le verre.
    private var aurora: some View {
        ZStack {
            blob(Color(red: 0.2, green: 0.55, blue: 0.75), diameter: 360, at: CGPoint(x: 0.1, y: 0.35))
            blob(Color(red: 0.5, green: 0.35, blue: 0.9), diameter: 400, at: CGPoint(x: 0.55, y: 0.75))
            blob(Color(red: 0.85, green: 0.35, blue: 0.55), diameter: 320, at: CGPoint(x: 0.95, y: 0.3))
        }
    }

    private func blob(_ color: Color, diameter: CGFloat, at unit: CGPoint) -> some View {
        Circle()
            .fill(color.opacity(0.28))
            .frame(width: diameter, height: diameter)
            .blur(radius: diameter * 0.4)
            .position(x: unit.x * size.width, y: unit.y * size.height)
    }
}
