/// Les répliques de chaque personnalité. `{prénom}` est remplacé par le prénom choisi.
extension CannedLines {
    static let nameToken = "{prénom}"

    private static let gentleLines = [
        "Coucou {prénom} ! Ça me fait plaisir de te voir ☁️",
        "Pense à boire un verre d'eau, {prénom} 💧",
        "Il fait beau dans ta notch aujourd'hui.",
        "Pssst… tu fais du super boulot.",
        "J'adore quand tu passes me voir !",
        "Une petite pause ? Même les nuages se reposent.",
        "Si je pleure, c'est juste de la pluie.",
        "Je suis fier de toi, {prénom}.",
    ]

    private static let playfulLines = [
        "Encore toi, {prénom} ? Je plaisante, j'adore 😄",
        "Tu cliques sur moi au lieu de bosser ? Je dis rien…",
        "Pssst… ton café refroidit.",
        "Un nuage pèse 500 tonnes. Moi je fais attention à ma ligne.",
        "Si je pleure, c'est juste de la pluie. Ou ton code.",
        "{prénom}, t'as pensé à sauvegarder ? Moi oui. Enfin je crois.",
        "Arrête de me chatouiller !",
        "Je surveille ton écran… gentiment 👀",
    ]

    private static let zenLines = [
        "Respire, {prénom}. Tout va bien.",
        "Une petite pause ? Même les nuages se reposent.",
        "Bois un verre d'eau, doucement.",
        "Le ciel n'est jamais pressé.",
        "Chaque nuage passe. Ce bug aussi.",
        "Inspire… expire… et on reprend.",
        "Tu avances bien, {prénom}. Un pas après l'autre.",
        "Regarde au loin quelques secondes, tes yeux te diront merci.",
    ]

    /// Répliques d'une personnalité, avec le prénom. Sans prénom, celles qui l'utilisent sont écartées.
    public static func lines(for personality: Personality, name: String) -> [String] {
        let lines =
            switch personality {
            case .gentle: gentleLines
            case .playful: playfulLines
            case .zen: zenLines
            }
        guard !name.isEmpty else { return lines.filter { !$0.contains(nameToken) } }
        return lines.map { $0.replacingOccurrences(of: nameToken, with: name) }
    }

    /// Une réplique typique de la personnalité, pour la présenter.
    public static func sample(for personality: Personality, name: String) -> String {
        lines(for: personality, name: name)[0]
    }

    /// Les répliques correspondant aux préférences.
    public init(preferences: ZeboPreferences) {
        self.init(Self.lines(for: preferences.personality, name: preferences.name))
    }
}
