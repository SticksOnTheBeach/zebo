import SwiftUI
import Observation

/// Ce que Zebo est en train de dire.
@MainActor
@Observable
final class ZeboSpeech {
    /// Réplique en cours (nil = Zebo ne parle pas).
    private(set) var line: String?
    /// Change à chaque nouvelle réplique (fait sauter Zebo).
    private(set) var lineID = 0

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

    func say(_ text: String) {
        lineID += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            line = text
        }
    }
}
