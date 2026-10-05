import SwiftUI

/// Spirale (yeux étourdis).
struct SpiralShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let turns: CGFloat = 2.5
        let steps = 60
        var p = Path()
        for i in 0...steps {
            let f = CGFloat(i) / CGFloat(steps)
            let angle = f * turns * 2 * .pi
            let point = CGPoint(
                x: center.x + cos(angle) * f * maxRadius,
                y: center.y + sin(angle) * f * maxRadius)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        return p
    }
}
