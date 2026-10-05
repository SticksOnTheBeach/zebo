import SwiftUI

/// Silhouette de nuage autour du texte : un corps arrondi, de grosses bosses dessus,
/// des plus petites dessous et une de chaque côté. Chaque bosse gonfle et dégonfle à son rythme.
struct CloudBubbleShape: Shape {
    /// Temps en secondes, pour la respiration des bosses.
    var time: Double = 0

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        // Taille des bosses : jamais trop petite, pour qu'une bulle d'une ligne reste bien ronde.
        let s = max(rect.height, w * 0.3)
        var p = Path()
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: rect.height / 2, height: rect.height / 2),
                         style: .continuous)

        // Tailles variées pour que ça ne fasse pas une rangée de perles.
        let sizes: [CGFloat] = [1, 0.8, 0.95, 0.75, 0.9]
        var index = 0
        func puff(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
            let breath = 1 + 0.06 * CGFloat(sin(time * 1.7 + Double(index) * 1.9))
            index += 1
            let radius = r * breath
            p.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }

        // Grosses bosses sur le dessus
        let top = max(3, Int(w / 75))
        for i in 0..<top {
            let t = CGFloat(i) / CGFloat(top - 1)
            puff(rect.minX + w * (0.2 + 0.6 * t), rect.minY + s * 0.2, s * 0.42 * sizes[i % sizes.count])
        }
        // Petites bosses en dessous
        let bottom = max(2, Int(w / 90))
        for i in 0..<bottom {
            let t = CGFloat(i) / CGFloat(bottom - 1)
            puff(rect.minX + w * (0.28 + 0.44 * t), rect.maxY - s * 0.12, s * 0.32 * sizes[(i + 2) % sizes.count])
        }
        // Une bosse de chaque côté
        puff(rect.minX + s * 0.2, rect.midY + s * 0.04, s * 0.4)
        puff(rect.maxX - s * 0.2, rect.midY - s * 0.02, s * 0.43)
        return p
    }
}
