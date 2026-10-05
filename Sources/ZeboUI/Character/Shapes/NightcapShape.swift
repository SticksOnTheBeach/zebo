import SwiftUI

/// Bonnet de nuit posé sur la tête du nuage, la pointe retombant vers la droite.
/// Mêmes coordonnées que le personnage : grille 100 × 100 centrée.
struct NightcapShape: Shape {
    /// Le revers suit le haut de la tête ; le bonnet le dessine aussi pour qu'ils s'emboîtent.
    static let brimStart = CGPoint(x: -28, y: -29)
    static let brimControl = CGPoint(x: -4, y: -58)
    static let brimEnd = CGPoint(x: 19, y: -31)
    /// Bout de la pointe, où pend le pompon.
    static let tip = CGPoint(x: 40, y: -14)

    func path(in rect: CGRect) -> Path {
        let u = min(rect.width, rect.height) / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)
        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: center.x + p.x * u, y: center.y + p.y * u)
        }
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { point(CGPoint(x: x, y: y)) }

        var p = Path()
        p.move(to: point(Self.brimStart))
        p.addQuadCurve(to: point(4, -64), control: point(-24, -62))
        p.addQuadCurve(to: point(Self.tip), control: point(40, -64))
        p.addQuadCurve(to: point(Self.brimEnd), control: point(30, -42))
        p.addQuadCurve(to: point(Self.brimStart), control: point(Self.brimControl))
        p.closeSubpath()
        return p
    }
}

/// Revers du bonnet : une bande épaisse le long du haut de la tête.
struct NightcapBrimShape: Shape {
    func path(in rect: CGRect) -> Path {
        let u = min(rect.width, rect.height) / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)
        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: center.x + p.x * u, y: center.y + p.y * u)
        }

        var p = Path()
        p.move(to: point(NightcapShape.brimStart))
        p.addQuadCurve(to: point(NightcapShape.brimEnd), control: point(NightcapShape.brimControl))
        return p
    }
}
