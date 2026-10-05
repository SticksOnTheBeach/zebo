import SwiftUI
import ZeboCore

/// La couleur de chaque langage, inspirée de son logo (contours, coches, pastilles).
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
}
