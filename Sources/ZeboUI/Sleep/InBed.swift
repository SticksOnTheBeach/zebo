import SwiftUI

/// Le lit de Zebo, vu de face : la tête de lit et l'oreiller derrière lui, la couette par-dessus.
/// Quand il ne dort pas, le lit s'efface et Zebo reprend toute la place.
/// Mêmes coordonnées que le personnage : grille 100 × 100 centrée.
struct InBed<Sleeper: View>: View {
    var isAsleep: Bool
    @ViewBuilder var sleeper: Sleeper

    /// Taille et position de Zebo couché, pour laisser voir le lit autour de lui.
    private static var sleeperScale: CGFloat { 0.68 }
    private static var sleeperOffsetY: CGFloat { -4 }

    var body: some View {
        GeometryReader { geo in
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                Group {
                    headboard(u)
                    pillow(u)
                }
                .opacity(isAsleep ? 1 : 0)

                sleeper
                    .scaleEffect(isAsleep ? Self.sleeperScale : 1)
                    .offset(y: isAsleep ? Self.sleeperOffsetY * u : 0)

                Group {
                    bedFrame(u)
                    blanket(u)
                }
                .opacity(isAsleep ? 1 : 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func headboard(_ u: CGFloat) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: 16 * u, topTrailingRadius: 16 * u, style: .continuous)
            .fill(ZeboPalette.bedWood)
            .frame(width: 86 * u, height: 64 * u)
            .offset(y: 8 * u)
    }

    private func pillow(_ u: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6 * u, style: .continuous)
            .fill(ZeboPalette.pillow)
            .frame(width: 82 * u, height: 15 * u)
            .offset(y: 9 * u)
    }

    /// Couette avec un revers clair en haut, remontée jusque sous le menton.
    private func blanket(_ u: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6 * u, style: .continuous)
                .fill(ZeboPalette.blanket)
            RoundedRectangle(cornerRadius: 3 * u, style: .continuous)
                .fill(ZeboPalette.blanketFold)
                .frame(height: 5 * u)
        }
        .frame(width: 92 * u, height: 22 * u)
        .offset(y: 30 * u)
    }

    /// Sommier et pieds du lit.
    private func bedFrame(_ u: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2 * u)
                .fill(ZeboPalette.bedWood)
                .frame(width: 92 * u, height: 6 * u)
                .offset(y: 42 * u)
            ForEach([-41, 41], id: \.self) { x in
                RoundedRectangle(cornerRadius: 1.5 * u)
                    .fill(ZeboPalette.bedWood)
                    .frame(width: 5 * u, height: 8 * u)
                    .offset(x: CGFloat(x) * u, y: 46 * u)
            }
        }
    }
}
