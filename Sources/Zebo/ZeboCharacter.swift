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

    private static let cloudTop = Color(red: 1.00, green: 0.91, blue: 0.95)
    private static let cloudBottom = Color(red: 0.99, green: 0.78, blue: 0.87)
    private static let cloudShade = Color(red: 0.93, green: 0.62, blue: 0.75)
    private static let ink = Color(red: 0.24, green: 0.13, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            // 1 unité = 1/100 de la taille disponible.
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                // Couche plus foncée derrière : donne du volume, et part un peu
                // à l'opposé du regard (effet de profondeur).
                CloudShape()
                    .fill(Self.cloudShade)
                    .offset(x: -look.x * 2 * u, y: 3 * u)

                CloudShape()
                    .fill(LinearGradient(colors: [Self.cloudTop, Self.cloudBottom],
                                         startPoint: .top, endPoint: .bottom))

                // Le visage glisse vers le regard : le nuage a l'air de tourner.
                ZStack {
                    // Pas de pupilles : ce sont les yeux entiers qui suivent le regard.
                    Group {
                        eye(u).offset(x: -13 * u, y: 10 * u)
                        eye(u).offset(x: 13 * u, y: 10 * u)
                    }
                    .offset(x: look.x * 5 * u, y: look.y * 4 * u)

                    Smile()
                        .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                        .frame(width: 10 * u, height: 4 * u)
                        .offset(y: 27 * u)
                }
                .offset(x: look.x * 4 * u, y: look.y * 3 * u)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(headTilt, anchor: .bottom)
        }
    }

    /// Petit œil ovale noir ; en clignant, il s'aplatit jusqu'à devenir un trait.
    private func eye(_ u: CGFloat) -> some View {
        Capsule()
            .fill(Self.ink)
            .frame(width: 8 * u, height: max(13 * eyeOpenness, 2.5) * u)
    }
}

/// Silhouette de nuage : un socle arrondi surmonté de bosses, fusionnés en une seule forme.
private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Mêmes coordonnées que le personnage : grille 100 × 100 centrée.
        let u = min(rect.width, rect.height) / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)

        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> CGRect {
            CGRect(x: center.x + (x - r) * u, y: center.y + (y - r) * u,
                   width: 2 * r * u, height: 2 * r * u)
        }

        var p = Path()
        // Socle
        p.addRoundedRect(in: CGRect(x: center.x - 46 * u, y: center.y - 4 * u,
                                    width: 92 * u, height: 46 * u),
                         cornerSize: CGSize(width: 23 * u, height: 23 * u),
                         style: .continuous)
        // Bosses (de gauche à droite)
        p.addEllipse(in: circle(-30, 2, 19))
        p.addEllipse(in: circle(-4, -14, 29))
        p.addEllipse(in: circle(27, -2, 21))
        return p
    }
}

/// Petit sourire en arc.
private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 2))
        return p
    }
}
