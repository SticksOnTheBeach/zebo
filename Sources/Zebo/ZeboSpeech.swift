import Foundation
import Observation
import ZeboCore

/// Ce que Zebo est en train de dire, révélé lettre par lettre.
@MainActor
@Observable
final class ZeboSpeech {
    /// Réplique en cours (nil = Zebo ne parle pas).
    private(set) var line: String?
    /// Nombre de caractères déjà affichés (effet machine à écrire).
    private(set) var revealedCount = 0
    /// Change à chaque nouvelle réplique (fait sauter Zebo).
    private(set) var lineID = 0

    @ObservationIgnored private var speakingTask: Task<Void, Never>?

    @ObservationIgnored private let lineSource: any SpeechLineSource

    init(lineSource: any SpeechLineSource = CannedLines()) {
        self.lineSource = lineSource
    }

    func sayRandom() {
        say(lineSource.line(after: line))
    }

    /// Coupe la parole : la bulle disparaît tout de suite.
    func silence() {
        speakingTask?.cancel()
        line = nil
    }

    func say(_ text: String) {
        speakingTask?.cancel()
        lineID += 1
        revealedCount = 0
        line = text

        speakingTask = Task { [weak self] in
            for count in 1...text.count {
                try? await Task.sleep(for: .milliseconds(30))
                guard let self, !Task.isCancelled else { return }
                revealedCount = count
            }
            // Laisse le temps de lire avant de faire disparaître la bulle.
            try? await Task.sleep(for: .seconds(2.5 + Double(text.count) * 0.04))
            guard let self, !Task.isCancelled else { return }
            self.line = nil
        }
    }
}
