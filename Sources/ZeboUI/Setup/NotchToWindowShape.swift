import SwiftUI
import ZeboCore

/// La notch qui se détache et devient une fenêtre : le cadre glisse de `from` à `to`,
/// les petits arrondis creusés du haut disparaissent, puis les coins s'arrondissent comme une fenêtre.
/// `from` et `to` sont dans le repère de la vue qui dessine la forme (origine en haut à gauche).
struct NotchToWindowShape: Shape {
    var from: CGRect
    var to: CGRect
    /// 0 = la notch, 1 = la fenêtre.
    var progress: CGFloat
    /// Arrondi du bas de la notch : 28 ouverte, 12 fermée.
    var notchBottomRadius: CGFloat = 28
    /// Part de l'animation pendant laquelle les arrondis creusés du haut s'effacent.
    private static let flareFadeEnd: CGFloat = 0.3

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in _: CGRect) -> Path {
        let p = progress
        let rect = CGRect(
            x: lerp(from.minX, to.minX, p), y: lerp(from.minY, to.minY, p),
            width: lerp(from.width, to.width, p), height: lerp(from.height, to.height, p))
        let bottom = lerp(notchBottomRadius, SetupWindowLayout.cornerRadius, p)
        let flare = NotchModel.topCornerRadius * max(0, 1 - p / Self.flareFadeEnd)

        guard flare > 0 else {
            // Plus d'arrondis creusés : les coins du haut s'arrondissent à leur tour.
            let top = SetupWindowLayout.cornerRadius * (p - Self.flareFadeEnd) / (1 - Self.flareFadeEnd)
            return UnevenRoundedRectangle(
                topLeadingRadius: top, bottomLeadingRadius: bottom,
                bottomTrailingRadius: bottom, topTrailingRadius: top, style: .continuous
            ).path(in: rect)
        }
        return notchPath(in: rect, flare: flare, bottom: bottom)
    }

    /// Même silhouette que `NotchShape`, avec des arrondis creusés de taille `flare`.
    private func notchPath(in rect: CGRect, flare: CGFloat, bottom: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + flare, y: rect.minY + flare),
            control: CGPoint(x: rect.minX + flare, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + flare, y: rect.maxY - bottom))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + flare + bottom, y: rect.maxY),
            control: CGPoint(x: rect.minX + flare, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - flare - bottom, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - flare, y: rect.maxY - bottom),
            control: CGPoint(x: rect.maxX - flare, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - flare, y: rect.minY + flare))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - flare, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}
