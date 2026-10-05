import SwiftUI

/// Le lit de Zebo, vu de profil : tête de lit à gauche, pied de lit à droite, oreiller,
/// et Zebo bordé au milieu sous la couette. Quand il ne dort pas, le lit s'efface
/// et Zebo reprend toute la place.
/// Coordonnées : 1 unité = 1/100 de la hauteur, origine au centre (le lit est plus large que haut).
struct InBed<Sleeper: View>: View {
    var isAsleep: Bool
    @ViewBuilder var sleeper: Sleeper

    /// Taille et position de Zebo couché : assez petit pour laisser voir le lit autour de lui.
    private static var sleeperScale: CGFloat { 0.62 }
    private static var sleeperOffsetY: CGFloat { -3 }

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
                    .offset(y: isAsleep ? Self.sleeperOffsetY * u : 0)

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
            .offset(x: (-halfWidth + 24) * u, y: 13 * u)
    }

    /// Couette qui recouvre Zebo jusque sous le menton et retombe vers le pied du lit,
    /// avec un revers clair côté oreiller.
    private func blanket(_ u: CGFloat, halfWidth: CGFloat) -> some View {
        let width = halfWidth - 14 + 30
        return ZStack(alignment: .leading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 8 * u, bottomLeadingRadius: 3 * u,
                bottomTrailingRadius: 3 * u, topTrailingRadius: 3 * u, style: .continuous
            )
            .fill(ZeboPalette.blanket)
            UnevenRoundedRectangle(
                topLeadingRadius: 8 * u, bottomLeadingRadius: 3 * u, style: .continuous
            )
            .fill(ZeboPalette.blanketFold)
            .frame(width: 8 * u)
        }
        .frame(width: width * u, height: 18 * u)
        // De la gauche de Zebo jusqu'au pied du lit.
        .offset(x: (-30 + width / 2) * u, y: 25 * u)
    }
}
