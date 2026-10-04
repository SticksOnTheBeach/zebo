import SwiftUI
import Observation

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

    private var speakingTask: Task<Void, Never>?

    /// Répliques toutes faites, en attendant de brancher l'IA.
    private static let lines = [
        "Coucou ! Moi c'est Zebo ☁️",
        "Je te surveille… gentiment 👀",
        "Hé, pense à boire un verre d'eau !",
        "Il fait beau dans ta notch aujourd'hui.",
        "Pssst… tu codes super bien.",
        "Si je pleure, c'est juste de la pluie.",
        "J'adore quand tu cliques sur moi !",
        "Une petite pause ? Même les nuages se reposent.",
        "Bientôt on pourra vraiment discuter, promis.",
        "Un nuage pèse environ 500 tonnes. Moi je me sens léger pourtant.",
    ]

    func sayRandom() {
        // Évite de répéter deux fois de suite la même phrase.
        let next = Self.lines.filter { $0 != line }.randomElement() ?? Self.lines[0]
        say(next)
    }

    /// Coupe la parole : la bulle disparaît tout de suite.
    func silence() {
        speakingTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) {
            line = nil
        }
    }

    func say(_ text: String) {
        speakingTask?.cancel()
        lineID += 1
        revealedCount = 0
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            line = text
        }

        speakingTask = Task { [weak self] in
            for count in 1...text.count {
                try? await Task.sleep(for: .milliseconds(30))
                guard let self, !Task.isCancelled else { return }
                revealedCount = count
            }
            // Laisse le temps de lire avant de faire disparaître la bulle.
            try? await Task.sleep(for: .seconds(2.5 + Double(text.count) * 0.04))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.line = nil
            }
        }
    }
}
