import SwiftUI

/// De petites étincelles qui scintillent doucement, chacune à son rythme.
struct SparkleField: View {
    var count = 28

    @Environment(\.showsFinalAppearance) private var showsFinalAppearance

    var body: some View {
        // 20 images/s suffisent pour un scintillement lent.
        TimelineView(.animation(minimumInterval: 1 / 20, paused: showsFinalAppearance)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for index in 0..<count {
                    let sparkle = Sparkle(index: index)
                    let twinkle = 0.5 + 0.5 * sin(t * sparkle.speed + sparkle.phase)
                    let point = CGPoint(x: sparkle.x * size.width, y: sparkle.y * size.height)
                    let radius = sparkle.radius
                    context.opacity = 0.15 + 0.6 * twinkle
                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(.white))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Une étincelle, toujours au même endroit pour un même rang (pas de hasard d'une image à l'autre).
private struct Sparkle {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let speed: Double
    let phase: Double

    init(index: Int) {
        // Suite pseudo-aléatoire stable, à partir du rang.
        func unit(_ salt: Double) -> Double {
            let value = sin(Double(index) * 12.9898 + salt * 78.233) * 43_758.5453
            return value - value.rounded(.down)
        }
        x = unit(1)
        y = unit(2)
        radius = 0.6 + 1.0 * unit(3)
        speed = 0.6 + 1.4 * unit(4)
        phase = unit(5) * 2 * .pi
    }
}
