import SwiftUI

/// Bulle de dialogue en forme de nuage, sous la notch, reliée à Zebo par des points (comme en BD).
/// Elle vit dans sa propre fenêtre transparente, centrée sur la notch et collée en haut de l'écran.
struct SpeechBubbleView: View {
    let model: NotchModel
    let speech: ZeboSpeech

    static let windowSize = CGSize(width: 640, height: 360)

    /// Espace entre le bas de la notch et le haut de la bulle, occupé par les points.
    private let gap: CGFloat = 42
    private let maxTextWidth: CGFloat = 240
    private let ink = Color(red: 0.24, green: 0.13, blue: 0.20)

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let line = speech.line {
                ZStack(alignment: .topLeading) {
                    dots
                    bubble(line)
                        .offset(x: bubbleOrigin.x, y: bubbleOrigin.y)
                }
                // La bulle « sort » de Zebo.
                .transition(
                    .scale(scale: 0.3, anchor: UnitPoint(x: zeboCenter.x / Self.windowSize.width,
                                                         y: zeboCenter.y / Self.windowSize.height))
                    .combined(with: .opacity)
                )
            }
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height, alignment: .topLeading)
    }

    // MARK: - Géométrie (origine en haut à gauche de cette fenêtre)

    /// Les deux fenêtres partagent le même centre horizontal et le même haut d'écran.
    private var notchMinX: CGFloat { (Self.windowSize.width - model.notchSize.width) / 2 }

    private var zeboCenter: CGPoint {
        CGPoint(x: notchMinX + model.zeboFrame.midX, y: model.zeboFrame.midY)
    }

    /// Coin haut-gauche de la bulle : en dessous de la notch, un peu à droite de Zebo.
    private var bubbleOrigin: CGPoint {
        CGPoint(x: zeboCenter.x + 4, y: model.notchSize.height + gap)
    }

    // MARK: - Dessin

    private func bubble(_ line: String) -> some View {
        Text(typed(line))
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(ink)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: maxTextWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .background {
                PuffyBubbleShape()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            }
    }

    /// Trois points de plus en plus gros, de Zebo vers la bulle.
    private var dots: some View {
        let start = CGPoint(x: zeboCenter.x, y: model.notchSize.height + 7)
        let end = CGPoint(x: bubbleOrigin.x + 26, y: bubbleOrigin.y + 6)
        let steps: [(t: CGFloat, size: CGFloat)] = [(0.0, 6), (0.38, 9), (0.74, 12)]

        return ZStack(alignment: .topLeading) {
            ForEach(steps.indices, id: \.self) { i in
                let step = steps[i]
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    .frame(width: step.size, height: step.size)
                    .offset(x: start.x + (end.x - start.x) * step.t - step.size / 2,
                            y: start.y + (end.y - start.y) * step.t - step.size / 2)
            }
        }
    }

    /// Toute la phrase est mise en page dès le début (la bulle ne change pas de taille),
    /// mais la partie pas encore « dite » est transparente.
    private func typed(_ line: String) -> AttributedString {
        var text = AttributedString(line)
        let revealed = min(speech.revealedCount, line.count)
        let hiddenStart = text.characters.index(text.startIndex, offsetBy: revealed)
        text[hiddenStart...].foregroundColor = Color.clear
        return text
    }
}

/// Bulle « nuage » : un rectangle arrondi bordé de bosses.
struct PuffyBubbleShape: Shape {
    /// Rayon des bosses.
    var puff: CGFloat = 13

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inner = rect.insetBy(dx: puff, dy: puff)
        p.addRoundedRect(in: inner.insetBy(dx: -puff * 0.5, dy: -puff * 0.5),
                         cornerSize: CGSize(width: puff, height: puff))

        func puffs(from a: CGPoint, to b: CGPoint) {
            let length = hypot(b.x - a.x, b.y - a.y)
            // Bosses espacées d'environ 1,4 rayon : de petits creux entre elles.
            let count = max(1, Int((length / (puff * 1.4)).rounded()))
            for i in 0...count {
                let t = CGFloat(i) / CGFloat(count)
                let c = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                p.addEllipse(in: CGRect(x: c.x - puff, y: c.y - puff, width: puff * 2, height: puff * 2))
            }
        }

        let tl = CGPoint(x: inner.minX, y: inner.minY)
        let tr = CGPoint(x: inner.maxX, y: inner.minY)
        let bl = CGPoint(x: inner.minX, y: inner.maxY)
        let br = CGPoint(x: inner.maxX, y: inner.maxY)
        puffs(from: tl, to: tr)
        puffs(from: bl, to: br)
        puffs(from: tl, to: bl)
        puffs(from: tr, to: br)
        return p
    }
}
