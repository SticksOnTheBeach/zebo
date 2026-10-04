import SwiftUI

/// Bulle de dialogue en forme de nuage qui flotte sous la notch, reliée à Zebo par des points (comme en BD).
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
                // Animé à chaque image, mais seulement tant que Zebo parle.
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    ZStack(alignment: .topLeading) {
                        dots(time: t)
                        bubble(line, time: t)
                            .offset(x: bubbleOrigin.x, y: bubbleOrigin.y + bob(t))
                    }
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

    // MARK: - Flottement

    /// Le nuage monte et descend doucement (±3 pt).
    private func bob(_ t: Double) -> CGFloat {
        3 * sin(t * 1.6)
    }

    // MARK: - Dessin

    private func bubble(_ line: String, time t: Double) -> some View {
        CappedWidth(maxWidth: maxTextWidth) {
            Text(typed(line))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
        }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background {
                CloudBubbleShape(time: t)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            }
            // Il respire et tangue un peu, comme posé sur l'air.
            .scaleEffect(1 + 0.02 * sin(t * 1.3))
            .rotationEffect(.degrees(1.2 * sin(t * 0.9)))
    }

    /// Trois points de plus en plus gros, de Zebo vers le nuage ; chacun flotte à son rythme.
    private func dots(time t: Double) -> some View {
        let start = CGPoint(x: zeboCenter.x, y: model.notchSize.height + 7)
        let end = CGPoint(x: bubbleOrigin.x + 18, y: bubbleOrigin.y - 6 + bob(t))
        let steps: [(t: CGFloat, size: CGFloat)] = [(0.0, 6), (0.4, 9), (0.78, 12)]

        return ZStack(alignment: .topLeading) {
            ForEach(steps.indices, id: \.self) { i in
                let step = steps[i]
                let float = 2 * sin(t * 2 + Double(i) * 0.8)
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    .frame(width: step.size, height: step.size)
                    .offset(x: start.x + (end.x - start.x) * step.t - step.size / 2,
                            y: start.y + (end.y - start.y) * step.t - step.size / 2 + float)
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

/// Largeur = celle du texte sur une seule ligne, plafonnée à `maxWidth` (au-delà, le texte passe à la ligne).
/// Une bulle pour « Coucou ! » reste donc petite au lieu de prendre toute la largeur.
private struct CappedWidth: Layout {
    var maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let width = min(child.sizeThatFits(.unspecified).width, maxWidth)
        return child.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}
