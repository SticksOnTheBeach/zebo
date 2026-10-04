import SwiftUI
import Observation

/// Ce que fait Zebo quand on clique dessus : il parle… et si on insiste trop,
/// il tombe dans les pommes.
@MainActor
@Observable
final class ZeboBehavior {
    enum State {
        /// Dans la notch, tout va bien.
        case normal
        /// Sonné : yeux en spirale, étoiles autour de la tête.
        case dizzy
    }

    private(set) var state: State = .normal

    @ObservationIgnored private var recentClicks: [Date] = []
    @ObservationIgnored private let model: NotchModel
    @ObservationIgnored private let speech: ZeboSpeech

    /// Clics rapprochés qui le font tomber dans les pommes.
    private static let clicksToFaint = 5
    private static let clickWindow: TimeInterval = 3

    init(model: NotchModel, speech: ZeboSpeech) {
        self.model = model
        self.speech = speech
    }

    func poke() {
        guard state == .normal else { return }

        let now = Date()
        recentClicks = recentClicks.filter { now.timeIntervalSince($0) < Self.clickWindow } + [now]

        switch recentClicks.count {
        case Self.clicksToFaint...:
            faint()
        case Self.clicksToFaint - 1:
            speech.say("Arrête… j'ai la tête qui tourne 😵‍💫")
        case Self.clicksToFaint - 2:
            speech.say("Hé, doucement !")
        default:
            speech.sayRandom()
        }
    }

    private func faint() {
        recentClicks = []
        state = .dizzy
        speech.say("Ouuuh… je vois des étoiles…")

        Task {
            // Il titube un moment, puis reprend ses esprits.
            try? await Task.sleep(for: .seconds(1.8))
            state = .normal
        }
    }
}

/// Trajectoire de Zebo éjecté : un lancer avec gravité, qui tourne sur lui-même.
struct Flight {
    let start: Date
    /// Point de départ, dans la fenêtre plein écran (origine en haut à gauche).
    let origin: CGPoint
    /// Vitesse initiale en points/s (dy < 0 = vers le haut).
    let velocity: CGVector
    let size: CGFloat
    /// Vitesse de rotation en degrés/s.
    let spinSpeed: Double
    /// Hauteur de l'écran.
    let floorY: CGFloat

    static let gravity: CGFloat = 2200

    func position(at t: Double) -> CGPoint {
        let t = CGFloat(t)
        return CGPoint(x: origin.x + velocity.dx * t,
                       y: origin.y + velocity.dy * t + 0.5 * Self.gravity * t * t)
    }

    /// Temps pour sortir par le bas de l'écran.
    var duration: Double {
        let distance = floorY + size - origin.y
        let v = velocity.dy
        return Double((-v + sqrt(v * v + 2 * Self.gravity * distance)) / Self.gravity)
    }

    /// Il s'efface pendant la seconde moitié de la chute.
    func opacity(at y: CGFloat) -> Double {
        Double(max(0, min(1, 1 - (y - floorY * 0.45) / (floorY * 0.5))))
    }
}
