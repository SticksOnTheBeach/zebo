import SwiftUI
import ZeboCore

/// Couleurs et badge de chaque langage, inspirés de leurs logos.
extension Language {
    var color: Color {
        switch self {
        case .swift: Color(red: 0.94, green: 0.32, blue: 0.22)
        case .typescript: Color(red: 0.19, green: 0.47, blue: 0.78)
        case .javascript: Color(red: 0.97, green: 0.87, blue: 0.12)
        case .python: Color(red: 0.22, green: 0.46, blue: 0.67)
        case .rust: Color(red: 0.81, green: 0.26, blue: 0.17)
        case .kotlin: Color(red: 0.5, green: 0.32, blue: 1)
        case .java: Color(red: 0.91, green: 0.44, blue: 0)
        case .cpp: Color(red: 0, green: 0.35, blue: 0.61)
        case .csharp: Color(red: 0.41, green: 0.13, blue: 0.48)
        case .go: Color(red: 0, green: 0.68, blue: 0.85)
        case .php: Color(red: 0.47, green: 0.48, blue: 0.71)
        case .ruby: Color(red: 0.8, green: 0.2, blue: 0.18)
        }
    }

    /// Texte sur le badge (le logo pour Swift).
    var badge: String {
        switch self {
        case .swift: ""
        case .typescript: "TS"
        case .javascript: "JS"
        case .python: "Py"
        case .rust: "Rs"
        case .kotlin: "Kt"
        case .java: "Jv"
        case .cpp: "C++"
        case .csharp: "C#"
        case .go: "Go"
        case .php: "php"
        case .ruby: "Rb"
        }
    }

    /// Texte foncé sur les badges clairs (JavaScript).
    var badgeForeground: Color { self == .javascript ? .black : .white }
}

/// Le badge d'un langage : un carré arrondi à sa couleur, avec son sigle.
struct LanguageBadge: View {
    let language: Language
    var size: CGFloat = 38

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(language.color.gradient)
            .frame(width: size, height: size)
            .overlay {
                if language == .swift {
                    Image(systemName: "swift")
                        .font(.system(size: size * 0.5, weight: .bold))
                } else {
                    Text(language.badge)
                        .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                }
            }
            .foregroundStyle(language.badgeForeground)
    }
}
