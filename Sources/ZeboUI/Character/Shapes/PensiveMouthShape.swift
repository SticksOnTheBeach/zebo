import SwiftUI

/// Moue pensive : un arc bombé vers le haut, plus marqué d'un côté.
struct PensiveMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.3),
                       control: CGPoint(x: rect.midX - rect.width * 0.15, y: rect.minY - rect.height * 0.6))
        return p
    }
}
