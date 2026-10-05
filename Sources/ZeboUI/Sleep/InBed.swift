import SwiftUI

/// Le lit de Zebo, vu de profil : tête de lit à gauche, pied de lit à droite, oreiller.
/// Zebo (qui s'allonge tout seul quand il dort) y est couché, la tête sur l'oreiller,
/// bordé sous la couette. Quand il ne dort pas, le lit s'efface et Zebo reprend toute la place.
/// Coordonnées : 1 unité = 1/100 de la hauteur, origine au centre (le lit est plus large que haut).
struct InBed<Sleeper: View>: View {
    var isAsleep: Bool
    @ViewBuilder var sleeper: Sleeper

    /// Taille et position de Zebo couché : assez petit pour tenir sur le matelas,
    /// la tête contre la tête de lit.
    private static var sleeperScale: CGFloat { 0.52 }
    /// Distance entre le centre de Zebo couché et la tête de lit.
    private static var sleeperDistanceFromHeadboard: CGFloat { 30 }
    private static var sleeperOffsetY: CGFloat { -4 }

    var body: some View {
        GeometryReader { geo in
            let u = geo.size.height / 100
            let halfWidth = geo.size.width / 2 / u

            ZStack {
                Group {
                    headboard(u, halfWidth: halfWidth)
                    footboard(u, halfWidth: halfWidth)
                    mattress(u, halfWidth: halfWidth)
                    pillow(u, halfWidth: halfWidth)
                }
                .opacity(isAsleep ? 1 : 0)

                sleeper
                    .scaleEffect(isAsleep ? Self.sleeperScale : 1)
                    .offset(
                        x: isAsleep ? (-halfWidth + Self.sleeperDistanceFromHeadboard) * u : 0,
                        y: isAsleep ? Self.sleeperOffsetY * u : 0)

                blanket(u, halfWidth: halfWidth)
                    .opacity(isAsleep ? 1 : 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Haut montant arrondi à gauche, qui descend jusqu'au sol.
    private func headboard(_ u: CGFloat, halfWidth: CGFloat) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: 5 * u, topTrailingRadius: 5 * u, style: .continuous)
            .fill(ZeboPalette.bedWood)
            .frame(width: 9 * u, height: 64 * u)
            .offset(x: (-halfWidth + 4.5) * u, y: 12 * u)
    }

    /// Pied de lit, plus bas, à droite.
    private func footboard(_ u: CGFloat, halfWidth: CGFloat) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: 4 * u, topTrailingRadius: 4 * u, style: .continuous)
            .fill(ZeboPalette.bedWood)
            .frame(width: 8 * u, height: 38 * u)
            .offset(x: (halfWidth - 4) * u, y: 25 * u)
    }

    /// Matelas posé sur le sommier, entre les deux montants.
    private func mattress(_ u: CGFloat, halfWidth: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2 * u)
                .fill(ZeboPalette.bedWood)
                .frame(width: (halfWidth * 2 - 10) * u, height: 8 * u)
                .offset(y: 34 * u)
            RoundedRectangle(cornerRadius: 4 * u, style: .continuous)
                .fill(ZeboPalette.pillow)
                .frame(width: (halfWidth * 2 - 16) * u, height: 12 * u)
                .offset(y: 25 * u)
        }
    }

    /// Oreiller contre la tête de lit.
    private func pillow(_ u: CGFloat, halfWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 7 * u, style: .continuous)
            .fill(ZeboPalette.pillow)
            .frame(width: 26 * u, height: 16 * u)
            .rotationEffect(.degrees(-8))
            .offset(x: (-halfWidth + 20) * u, y: 13 * u)
    }

    /// Couette remontée jusque sous son visage : une bosse là où elle recouvre son corps,
    /// puis elle s'aplatit jusqu'au pied du lit. Revers clair côté oreiller.
    private func blanket(_ u: CGFloat, halfWidth: CGFloat) -> some View {
        let shape = BlanketShape(
            start: -halfWidth + Self.sleeperDistanceFromHeadboard + 9,
            end: halfWidth - 8)
        return ZStack {
            shape.fill(ZeboPalette.blanket)
            shape.fold
                .stroke(ZeboPalette.blanketFold, style: StrokeStyle(lineWidth: 5 * u, lineCap: .round))
        }
    }
}

/// Silhouette de la couette vue de profil, en unités de la grille du lit (1/100 de la hauteur).
private struct BlanketShape: Shape {
    /// Bords gauche (côté visage) et droit (pied du lit).
    var start: CGFloat
    var end: CGFloat

    private static let bottom: CGFloat = 32
    private static let humpTop: CGFloat = -25
    private static let flatTop: CGFloat = -2

    func path(in rect: CGRect) -> Path {
        outline(in: rect, closed: true)
    }

    /// Le revers : une bande claire le long du bord côté visage, légèrement en retrait.
    var fold: some Shape {
        FoldShape(blanket: self)
    }

    fileprivate func outline(in rect: CGRect, closed: Bool) -> Path {
        let u = rect.height / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: center.x + x * u, y: center.y + y * u)
        }

        var p = Path()
        p.move(to: point(start, Self.bottom))
        p.addLine(to: point(start, 8))
        // La bosse : son corps sous la couette, remontée jusque sous le menton.
        p.addQuadCurve(to: point(start + 8, -20), control: point(start, -14))
        p.addQuadCurve(to: point(start + 18, Self.humpTop), control: point(start + 12, Self.humpTop - 1))
        p.addQuadCurve(to: point(start + 44, Self.flatTop), control: point(start + 32, Self.humpTop))
        guard closed else { return p }
        // Puis à plat jusqu'au pied du lit.
        p.addLine(to: point(end - 5, Self.flatTop))
        p.addQuadCurve(to: point(end, Self.flatTop + 5), control: point(end, Self.flatTop))
        p.addLine(to: point(end, Self.bottom))
        p.closeSubpath()
        return p
    }
}

/// Le bord gauche de la couette, décalé vers l'intérieur pour dessiner le revers.
private struct FoldShape: Shape {
    var blanket: BlanketShape

    func path(in rect: CGRect) -> Path {
        let u = rect.height / 100
        var inset = blanket
        inset.start += 3
        return inset.outline(in: rect, closed: false)
            .trimmedPath(from: 0.08, to: 0.5)
            .applying(CGAffineTransform(translationX: 0, y: 2 * u))
    }
}
