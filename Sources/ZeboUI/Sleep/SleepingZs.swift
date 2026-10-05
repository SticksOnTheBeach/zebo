import SwiftUI

/// Des « z » qui s'échappent de la tête de Zebo endormi : chacun monte en diagonale
/// en grossissant, apparaît puis s'efface, et le suivant prend le relais.
/// Mêmes coordonnées que le personnage : grille 100 × 100 centrée.
struct SleepingZs: View {
    var isActive: Bool

    var body: some View {
        // Une si petite animation n'a pas besoin de plus de 20 images/s.
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !isActive)) { timeline in
            SleepingZsFrame(time: timeline.date.timeIntervalSinceReferenceDate)
        }
        .opacity(isActive ? 1 : 0)
        .allowsHitTesting(false)
    }
}

/// Une image de l'animation des « z », à l'instant `time` (en secondes).
struct SleepingZsFrame: View {
    var time: Double

    private static let count = 3
    /// Durée de vie d'un « z », de son apparition à sa disparition.
    private static let lifetime = 2.7
    /// Trajet d'un « z » : du haut de la tête vers la droite, en montant un peu.
    /// Il reste sous le haut du cadre : notch fermée, au-dessus c'est le bord de l'écran.
    private static let start = CGPoint(x: 24, y: -20)
    private static let end = CGPoint(x: 54, y: -42)

    var body: some View {
        GeometryReader { geo in
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                ForEach(0..<Self.count, id: \.self) { i in
                    // Chaque « z » est décalé d'un tiers de cycle sur le précédent.
                    let offset = Double(i) / Double(Self.count)
                    let progress = (time / Self.lifetime + offset).truncatingRemainder(dividingBy: 1)
                    letter(progress: progress, u: u)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func letter(progress: Double, u: CGFloat) -> some View {
        let p = CGFloat(progress)
        // Ondulation légère, comme s'il flottait.
        let wobble = sin(progress * 2 * .pi) * 3
        return Text("z")
            .font(.system(size: (10 + 8 * p) * u, weight: .heavy, design: .rounded))
            .foregroundStyle(ZeboPalette.sleepZ)
            // Apparaît en douceur au départ, s'efface en arrivant.
            .opacity(sin(progress * .pi))
            .offset(
                x: (Self.start.x + (Self.end.x - Self.start.x) * p + wobble) * u,
                y: (Self.start.y + (Self.end.y - Self.start.y) * p) * u)
    }
}
