/// Le genre de projet qu'on crée avec Zebo : le thème (web) ou le langage.
public enum ProjectKind: String, Codable, CaseIterable, Sendable {
    case web, c, cpp, python, rust, java, swift, kotlin, go, csharp

    public var name: String {
        switch self {
        case .web: "Web"
        case .c: "C"
        case .cpp: "C++"
        case .python: "Python"
        case .rust: "Rust"
        case .java: "Java"
        case .swift: "Swift"
        case .kotlin: "Kotlin"
        case .go: "Go"
        case .csharp: "C#"
        }
    }

    /// Nom du logo dans les ressources.
    public var logoName: String { rawValue }

    /// Extensions des fichiers de ce genre de projet (sans le point).
    public var fileExtensions: Set<String> {
        switch self {
        case .web: ["html", "css", "scss", "js", "jsx", "ts", "tsx", "vue", "svelte"]
        case .c: ["c", "h"]
        case .cpp: ["cpp", "cc", "cxx", "hpp", "hh", "hxx"]
        case .python: ["py", "ipynb"]
        case .rust: ["rs"]
        case .java: ["java"]
        case .swift: ["swift"]
        case .kotlin: ["kt", "kts"]
        case .go: ["go"]
        case .csharp: ["cs", "csproj"]
        }
    }

    /// Noms habituels d'un workspace de ce genre (en minuscules).
    public var folderNameHints: [String] {
        switch self {
        case .web: ["web", "websites", "sites", "frontend", "front"]
        case .c: ["c"]
        case .cpp: ["c++", "cpp", "cplusplus"]
        case .python: ["python", "py"]
        case .rust: ["rust", "rs"]
        case .java: ["java"]
        case .swift: ["swift", "ios", "macos", "apple"]
        case .kotlin: ["kotlin", "android"]
        case .go: ["go", "golang"]
        case .csharp: ["c#", "csharp", "dotnet", ".net"]
        }
    }

    /// Nom de dossier proposé pour un nouveau workspace de ce genre.
    public var suggestedWorkspaceName: String { name }
}
