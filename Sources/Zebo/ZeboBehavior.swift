import SwiftUI
import Observation

/// Ce que fait Zebo quand on clique dessus.
@MainActor
@Observable
final class ZeboBehavior {
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
        let now = Date()
        recentClicks = recentClicks.filter { now.timeIntervalSince($0) < Self.clickWindow } + [now]

        switch recentClicks.count {
        case Self.clicksToFaint - 1:
            speech.say("Arrête… j'ai la tête qui tourne 😵‍💫")
        case Self.clicksToFaint - 2:
            speech.say("Hé, doucement !")
        default:
            speech.sayRandom()
        }
    }
}
