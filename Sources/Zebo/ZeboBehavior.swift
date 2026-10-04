import SwiftUI
import Observation

/// Ce que fait Zebo quand on clique dessus.
@MainActor
@Observable
final class ZeboBehavior {
    @ObservationIgnored private let model: NotchModel
    @ObservationIgnored private let speech: ZeboSpeech

    init(model: NotchModel, speech: ZeboSpeech) {
        self.model = model
        self.speech = speech
    }

    func poke() {
        speech.sayRandom()
    }
}
