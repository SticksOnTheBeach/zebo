/// Les langages de programmation qu'on peut choisir comme préféré.
public enum Language: String, Codable, CaseIterable, Sendable {
    case swift, typescript, javascript, python, rust, kotlin, java, cpp, csharp, go, php, ruby

    /// Nom complet.
    public var name: String {
        switch self {
        case .swift: "Swift"
        case .typescript: "TypeScript"
        case .javascript: "JavaScript"
        case .python: "Python"
        case .rust: "Rust"
        case .kotlin: "Kotlin"
        case .java: "Java"
        case .cpp: "C++"
        case .csharp: "C#"
        case .go: "Go"
        case .php: "PHP"
        case .ruby: "Ruby"
        }
    }

    /// Nom court, pour tenir dans l'aile de la notch.
    public var shortName: String {
        switch self {
        case .typescript: "TS"
        case .javascript: "JS"
        case .python: "Py"
        case .kotlin: "Kt"
        default: name
        }
    }
}
