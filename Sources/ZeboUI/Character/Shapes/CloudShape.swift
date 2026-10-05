import SwiftUI

/// Silhouette de nuage : un socle arrondi surmonté de bosses, fusionnés en une seule forme.
struct CloudShape: Shape {
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
