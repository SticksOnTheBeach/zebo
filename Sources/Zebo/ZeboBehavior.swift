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
