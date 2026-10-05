/// Ce que l'on règle pendant la configuration de Zebo.
public struct ZeboPreferences: Codable, Equatable, Sendable {
    /// Comment Zebo t'appelle.
    public var name: String
    /// Sa façon de parler.
    public var personality: Personality
    /// L'heure dans l'aile droite de la notch fermée.
    public var showsClock: Bool
    /// Notch fermée, Zebo dort dans son lit (sinon il reste éveillé).
    public var sleepsWhenClosed: Bool
    /// L'éditeur de code choisi, pour pouvoir le lancer (absent des anciennes préférences).
    public var ide: IDEChoice?

    public static let standard = ZeboPreferences(
        name: "", personality: .gentle, showsClock: true, sleepsWhenClosed: true)

    public init(
        name: String, personality: Personality, showsClock: Bool, sleepsWhenClosed: Bool, ide: IDEChoice? = nil
    ) {
        self.name = name
        self.personality = personality
        self.showsClock = showsClock
        self.sleepsWhenClosed = sleepsWhenClosed
        self.ide = ide
    }
}

/// La façon de parler de Zebo.
public enum Personality: String, Codable, CaseIterable, Sendable {
    /// Des petits mots gentils.
    case gentle
    /// Il te taquine.
    case playful
    /// Calme, il t'aide à souffler.
    case zen
}
