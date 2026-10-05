import Foundation
import Observation

/// Ce que Zebo est en train de dire, révélé lettre par lettre.
@MainActor
@Observable
public final class ZeboSpeech {
    /// Réplique en cours (nil = Zebo ne parle pas).
    public private(set) var line: String?
    /// Nombre de caractères déjà affichés (effet machine à écrire).
    public private(set) var revealedCount = 0
    /// Change à chaque nouvelle réplique (fait sauter Zebo).
    public private(set) var lineID = 0

    @ObservationIgnored private var speakingTask: Task<Void, Never>?

    /// D'où viennent les répliques ; change quand on choisit la personnalité de Zebo.
    @ObservationIgnored public var lineSource: any SpeechLineSource

    public init(lineSource: any SpeechLineSource = CannedLines()) {
        self.lineSource = lineSource
    }

    public func sayRandom() {
        say(lineSource.line(after: line))
    }

    /// Coupe la parole : la bulle disparaît tout de suite.
    public func silence() {
        speakingTask?.cancel()
        line = nil
    }

    public func say(_ text: String) {
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
