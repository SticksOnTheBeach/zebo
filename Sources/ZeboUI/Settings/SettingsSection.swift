import SwiftUI

/// Les sections de la fenêtre de paramètres.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general, language, editors, notch, ai, permissions, advanced

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "Général"
        case .language: "Langage"
        case .editors: "Éditeurs"
        case .notch: "Notch"
        case .ai: "Intelligence artificielle"
        case .permissions: "Autorisations"
        case .advanced: "Avancé"
        }
    }

    var symbol: String {
        switch self {
        case .general: "person.crop.circle.fill"
        case .language: "curlybraces"
        case .editors: "chevron.left.forwardslash.chevron.right"
        case .notch: "rectangle.topthird.inset.filled"
        case .ai: "sparkles"
        case .permissions: "checkmark.shield.fill"
        case .advanced: "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: .blue
        case .language: .orange
        case .editors: .purple
        case .notch: .teal
        case .ai: .pink
        case .permissions: .green
        case .advanced: .gray
        }
    }
}
