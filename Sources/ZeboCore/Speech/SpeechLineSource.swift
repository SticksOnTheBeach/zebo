/// D'où viennent les répliques de Zebo. Aujourd'hui une liste toute faite ;
/// plus tard, une IA pourra prendre le relais sans toucher au reste.
public protocol SpeechLineSource: Sendable {
    /// Prochaine réplique, en évitant si possible de répéter `previous`.
    func line(after previous: String?) -> String
}

/// Répliques toutes faites, tirées au hasard.
public struct CannedLines: SpeechLineSource {
    public static let defaultLines = [
        "Coucou ! Moi c'est Zebo ☁️",
        "Je te surveille… gentiment mon gars fais beleck",
        "Hé, pense à boire un verre d'eau !",
        "Il fait beau dans ta notch aujourd'hui enculé",
        "Pssst… tu codes super bien.",
        "Si je pleure, c'est juste de la pluie.",
        "J'adore quand tu cliques sur moi !",
        "Une petite pause ? Même les nuages se reposent.",
        "Bientôt on pourra vraiment discuter, promis.",
        "Un nuage pèse environ 500 tonnes. Moi je me sens léger pourtant.",
    ]

    private let lines: [String]

    /// - Precondition: `lines` n'est pas vide.
    public init(_ lines: [String] = Self.defaultLines) {
        precondition(!lines.isEmpty, "Zebo a besoin d'au moins une réplique.")
        self.lines = lines
    }

    public func line(after previous: String?) -> String {
        lines.filter { $0 != previous }.randomElement() ?? lines[0]
    }
}
