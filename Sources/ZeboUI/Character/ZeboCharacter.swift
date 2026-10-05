import SwiftUI

/// Le personnage : un petit nuage rose, dessiné en formes SwiftUI.
/// Il s'adapte à la taille qu'on lui donne (tout est calculé sur une grille de 100 × 100).
struct ZeboCharacter: View {
    /// Direction du regard, de -1 à 1 sur chaque axe (0,0 = regarde droit devant).
    var look: CGPoint = .zero
    /// 1 = yeux grands ouverts, 0 = fermés.
    var eyeOpenness: CGFloat = 1
    /// Inclinaison de la tête (pivote autour de la base du nuage).
    var headTilt: Angle = .zero
    var mood: ZeboMood = .calm
    /// Rotation des spirales et des étoiles (on la fait avancer pour les animer).
    var dizzySpin: Angle = .zero

    private static let cloudTop = Color(red: 1.00, green: 0.91, blue: 0.95)
    private static let cloudBottom = Color(red: 0.99, green: 0.78, blue: 0.87)
    private static let ink = Color(red: 0.24, green: 0.13, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            // 1 unité = 1/100 de la taille disponible.
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                CloudShape()
                    .fill(LinearGradient(colors: [Self.cloudTop, Self.cloudBottom],
                                         startPoint: .top, endPoint: .bottom))

                // Le visage glisse vers le regard : le nuage a l'air de tourner.
                ZStack {
                    // Pas de pupilles : ce sont les yeux entiers qui suivent le regard.
                    Group {
                        eye(u).offset(x: -13 * u, y: 10 * u)
                        eye(u).offset(x: 13 * u, y: 10 * u)

                        if mood == .thinking {
                            // Un sourcil bien haut, l'autre plus bas et penché : il se demande quelque chose.
                            BrowShape()
                                .stroke(Self.ink, style: StrokeStyle(lineWidth: 2.6 * u, lineCap: .round))
                                .frame(width: 10 * u, height: 4 * u)
                                .rotationEffect(.degrees(-14))
                                .offset(x: -13 * u, y: -7 * u)
                            BrowShape()
                                .stroke(Self.ink, style: StrokeStyle(lineWidth: 2.6 * u, lineCap: .round))
                                .frame(width: 10 * u, height: 1.5 * u)
                                .rotationEffect(.degrees(18))
                                .offset(x: 13 * u, y: 1 * u)
                        }
                    }
                    .offset(x: look.x * 5 * u, y: look.y * 4 * u)

                    switch mood {
                    case .dizzy:
                        // Bouche en « o » : il est sonné.
                        Ellipse()
                            .stroke(Self.ink, lineWidth: 2.5 * u)
                            .frame(width: 7 * u, height: 8 * u)
                            .offset(y: 28 * u)
                    case .thinking:
                        // Moue « hmm » un peu de travers.
                        PensiveMouthShape()
                            .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                            .frame(width: 10 * u, height: 3 * u)
                            .rotationEffect(.degrees(-8))
                            .offset(x: -1 * u, y: 28 * u)
                    case .calm:
                        SmileShape()
                            .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                            .frame(width: 10 * u, height: 4 * u)
                            .offset(y: 27 * u)
                    }
                }
                .offset(x: look.x * 4 * u, y: look.y * 3 * u)

                if mood == .dizzy {
                    stars(u)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(headTilt, anchor: .bottom)
        }
    }

    /// Petit œil ovale noir ; en clignant, il s'aplatit jusqu'à devenir un trait.
    /// Étourdi, il devient une spirale qui tourne.
    @ViewBuilder
    private func eye(_ u: CGFloat) -> some View {
        if mood == .dizzy {
            SpiralShape()
                .stroke(Self.ink, style: StrokeStyle(lineWidth: 2.2 * u, lineCap: .round))
                .frame(width: 15 * u, height: 15 * u)
                .rotationEffect(dizzySpin)
        } else {
            Capsule()
                .fill(Self.ink)
                .frame(width: 8 * u, height: max(13 * eyeOpenness, 2.5) * u)
        }
    }

    /// Trois étoiles qui tournent en rond au-dessus de la tête.
    private func stars(_ u: CGFloat) -> some View {
        ForEach(0..<3, id: \.self) { i in
            let angle = dizzySpin.radians + Double(i) * 2 * .pi / 3
            // Plus petites quand elles passent « derrière » la tête : effet de perspective.
            let depth = 0.75 + 0.25 * sin(angle)
            StarShape()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.3))
                .frame(width: 11 * u, height: 11 * u)
                .scaleEffect(depth)
                .offset(x: cos(angle) * 34 * u, y: (-44 + sin(angle) * 7) * u)
        }
    }
}
