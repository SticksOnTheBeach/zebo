import SwiftUI

/// Bulle de dialogue en forme de nuage, sous la notch, reliée à Zebo par des points (comme en BD).
/// Elle vit dans sa propre fenêtre transparente, centrée sur la notch et collée en haut de l'écran.
struct SpeechBubbleView: View {
    let model: NotchModel
    let speech: ZeboSpeech

    static let windowSize = CGSize(width: 640, height: 360)

    /// Espace entre le bas de la notch et le haut de la bulle, occupé par les points.
    private let gap: CGFloat = 50
    private let maxTextWidth: CGFloat = 220
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

    /// Coin haut-gauche de la zone de texte : en dessous de la notch, un peu à droite de Zebo.
    /// Les bosses du nuage débordent tout autour.
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
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background {
                CloudBubbleShape()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            }
    }

    /// Trois points de plus en plus gros, de Zebo vers le nuage.
    private var dots: some View {
        let start = CGPoint(x: zeboCenter.x, y: model.notchSize.height + 7)
        let end = CGPoint(x: bubbleOrigin.x + 18, y: bubbleOrigin.y - 6)
        let steps: [(t: CGFloat, size: CGFloat)] = [(0.0, 6), (0.4, 9), (0.78, 12)]

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

/// Silhouette de nuage autour du texte : un corps arrondi, de grosses bosses dessus,
/// des plus petites dessous et une de chaque côté.
struct CloudBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: h / 2, height: h / 2), style: .continuous)

        // Tailles variées pour que ça ne fasse pas une rangée de perles.
        let sizes: [CGFloat] = [1, 0.8, 0.95, 0.75, 0.9]
        func puff(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
            p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }

        // Grosses bosses sur le dessus
        let top = max(2, Int(w / 75))
        for i in 0..<top {
            let t = CGFloat(i) / CGFloat(top - 1)
            puff(rect.minX + w * (0.2 + 0.6 * t), rect.minY + h * 0.18, h * 0.45 * sizes[i % sizes.count])
        }
        // Petites bosses en dessous
        let bottom = max(2, Int(w / 90))
        for i in 0..<bottom {
            let t = CGFloat(i) / CGFloat(bottom - 1)
            puff(rect.minX + w * (0.28 + 0.44 * t), rect.maxY - h * 0.12, h * 0.34 * sizes[(i + 2) % sizes.count])
        }
        // Une bosse de chaque côté
        puff(rect.minX + h * 0.22, rect.midY + h * 0.05, h * 0.42)
        puff(rect.maxX - h * 0.22, rect.midY - h * 0.02, h * 0.46)
        return p
    }
}
