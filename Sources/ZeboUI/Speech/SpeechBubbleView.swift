import SwiftUI
import ZeboCore

/// Bulle de dialogue en forme de nuage qui flotte sous la notch, reliée à Zebo par des points (comme en BD).
/// Elle vit dans sa propre fenêtre transparente, centrée sur la notch et collée en haut de l'écran.
public struct SpeechBubbleView: View {
    public static let windowSize = CGSize(width: 640, height: 420)

    /// Espace entre le bas de la notch et le haut de la bulle, occupé par les points.
    private let gap: CGFloat = 50
    private let maxTextWidth: CGFloat = 220
    private let model: NotchModel
    private let speech: ZeboSpeech

    /// Début de la réplique en cours : les points se mettent à « pop » à partir de là.
    @State private var lineStart = Date()

    public init(model: NotchModel, speech: ZeboSpeech) {
        self.model = model
        self.speech = speech
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if let line = speech.line {
                // Animé à chaque image, mais seulement tant que Zebo parle.
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    ZStack(alignment: .topLeading) {
                        dots(time: t, elapsed: timeline.date.timeIntervalSince(lineStart))
                        bubble(line, time: t)
                            .offset(x: bubbleOrigin.x, y: bubbleOrigin.y + bob(t))
                    }
                }
                // La bulle « sort » de Zebo.
                .transition(
                    .scale(
                        scale: 0.3,
                        anchor: UnitPoint(
                            x: zeboCenter.x / Self.windowSize.width,
                            y: zeboCenter.y / Self.windowSize.height)
                    )
                    .combined(with: .opacity)
                )
            }
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height, alignment: .topLeading)
        // La bulle surgit avec un ressort et s'efface en douceur.
        .animation(
            speech.line == nil ? .easeOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.7),
            value: speech.line
        )
        .onChange(of: speech.lineID, initial: true) { lineStart = Date() }
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
                .foregroundStyle(ZeboPalette.ink)
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
    /// Ils apparaissent un à un depuis Zebo, puis s'effacent ensemble, en boucle.
    private func dots(time t: Double, elapsed: Double) -> some View {
        let start = CGPoint(x: zeboCenter.x, y: model.notchSize.height + 7)
        let end = CGPoint(x: bubbleOrigin.x + 18, y: bubbleOrigin.y - 6 + bob(t))
        let steps: [(t: CGFloat, size: CGFloat)] = [(0.0, 6), (0.4, 9), (0.78, 12)]
        let period = 2.4
        let phase = max(elapsed, 0).truncatingRemainder(dividingBy: period) / period
        // Disparition commune à la fin du cycle.
        let fade = 1 - min(max((phase - 0.8) / 0.15, 0), 1)

        return ZStack(alignment: .topLeading) {
            ForEach(steps.indices, id: \.self) { i in
                let step = steps[i]
                let float = 2 * sin(t * 2 + Double(i) * 0.8)
                // Chacun « pop » à son tour, avec un léger rebond.
                let pop = min(max((phase - 0.05 - Double(i) * 0.15) / 0.12, 0), 1)
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    .frame(width: step.size, height: step.size)
                    .scaleEffect(Self.easeOutBack(pop))
                    .opacity(fade)
                    .offset(
                        x: start.x + (end.x - start.x) * step.t - step.size / 2,
                        y: start.y + (end.y - start.y) * step.t - step.size / 2 + float)
            }
        }
    }

    /// Courbe qui dépasse un peu sa cible avant de s'y poser (effet « pop »).
    private static func easeOutBack(_ x: Double) -> Double {
        let c = 1.7
        let t = x - 1
        return 1 + (c + 1) * t * t * t + c * t * t
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
