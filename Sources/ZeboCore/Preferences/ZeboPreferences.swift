/// Ce que l'on règle pendant la configuration de Zebo.
public struct ZeboPreferences: Codable, Equatable, Sendable {
    /// Comment Zebo t'appelle.
    public var name: String
    /// L'heure dans l'aile droite de la notch fermée.
    public var showsClock: Bool
    /// Notch fermée, Zebo dort dans son lit (sinon il reste éveillé).
    public var sleepsWhenClosed: Bool
    /// L'éditeur de code choisi, pour pouvoir le lancer (absent des anciennes préférences).
    public var ide: IDEChoice?

    public static let standard = ZeboPreferences(
        name: "", showsClock: true, sleepsWhenClosed: true)

    public init(
        name: String, showsClock: Bool, sleepsWhenClosed: Bool, ide: IDEChoice? = nil
    ) {
        self.name = name
        self.showsClock = showsClock
        self.sleepsWhenClosed = sleepsWhenClosed
        self.ide = ide
    }
}
