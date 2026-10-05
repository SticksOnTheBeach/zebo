/// Ce que l'on règle pendant la configuration de Zebo.
public struct ZeboPreferences: Equatable, Sendable {
    /// Comment Zebo t'appelle.
    public var name: String
    /// L'heure dans l'aile droite de la notch fermée.
    public var showsClock: Bool
    /// Notch fermée, Zebo dort dans son lit (sinon il reste éveillé).
    public var sleepsWhenClosed: Bool
    /// Les éditeurs de code choisis, pour pouvoir les lancer.
    public var ides: [IDEChoice]

    public static let standard = ZeboPreferences(name: "", showsClock: true, sleepsWhenClosed: true)

    public init(name: String, showsClock: Bool, sleepsWhenClosed: Bool, ides: [IDEChoice] = []) {
        self.name = name
        self.showsClock = showsClock
        self.sleepsWhenClosed = sleepsWhenClosed
        self.ides = ides
    }
}

/// Les réglages manquants prennent leur valeur par défaut : des préférences enregistrées
/// par une version plus ancienne se relisent toujours.
extension ZeboPreferences: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, showsClock, sleepsWhenClosed, ides
        /// Ancienne version : un seul éditeur.
        case ide
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let standard = Self.standard
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? standard.name
        showsClock = try container.decodeIfPresent(Bool.self, forKey: .showsClock) ?? standard.showsClock
        sleepsWhenClosed =
            try container.decodeIfPresent(Bool.self, forKey: .sleepsWhenClosed) ?? standard.sleepsWhenClosed
        if let ides = try container.decodeIfPresent([IDEChoice].self, forKey: .ides) {
            self.ides = ides
        } else {
            ides = try container.decodeIfPresent(IDEChoice.self, forKey: .ide).map { [$0] } ?? []
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(showsClock, forKey: .showsClock)
        try container.encode(sleepsWhenClosed, forKey: .sleepsWhenClosed)
        try container.encode(ides, forKey: .ides)
    }
}
