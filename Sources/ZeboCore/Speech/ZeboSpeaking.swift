/// Ce dont le comportement a besoin pour faire parler Zebo.
@MainActor
public protocol ZeboSpeaking: AnyObject {
    /// Dit une réplique choisie par la source de répliques.
    func sayRandom()
    func say(_ text: String)
    /// Coupe la parole immédiatement.
    func silence()
}

extension ZeboSpeech: ZeboSpeaking {}
