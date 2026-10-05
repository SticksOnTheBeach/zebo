/// Les répliques de Zebo une fois configuré : `{prénom}` est remplacé par le prénom choisi.
extension CannedLines {
    static let nameToken = "{prénom}"

    private static let personalizedLines = [
        "Coucou {prénom} ! Ça me fait plaisir de te voir ☁️",
        "Pense à boire un verre d'eau, {prénom} 💧",
        "Il fait beau dans ta notch aujourd'hui.",
        "Pssst… tu fais du super boulot.",
        "J'adore quand tu passes me voir !",
        "Une petite pause ? Même les nuages se reposent.",
        "Si je pleure, c'est juste de la pluie.",
        "Je suis fier de toi, {prénom}.",
    ]

    /// Les répliques avec le prénom. Sans prénom, celles qui l'utilisent sont écartées.
    public static func lines(name: String) -> [String] {
        guard !name.isEmpty else { return personalizedLines.filter { !$0.contains(nameToken) } }
        return personalizedLines.map { $0.replacingOccurrences(of: nameToken, with: name) }
    }

    /// Les répliques correspondant aux préférences.
    public init(preferences: ZeboPreferences) {
        self.init(Self.lines(name: preferences.name))
    }
}
