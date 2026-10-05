import SwiftUI
import ZeboCore

/// Comment présenter chaque widget de la notch dans la configuration.
extension NotchWidget {
    var title: String {
        switch self {
        case .clock: "L'heure"
        case .date: "La date du jour"
        case .commits: "Tes commits du jour"
        case .language: "Ton langage préféré"
        }
    }

    /// Nom court, pour le récapitulatif.
    var shortTitle: String {
        switch self {
        case .clock: "Heure"
        case .date: "Date"
        case .commits: "Commits"
        case .language: "Langage"
        }
    }

    var symbol: String {
        switch self {
        case .clock: "clock.fill"
        case .date: "calendar"
        case .commits: "arrow.triangle.branch"
        case .language: "chevron.left.forwardslash.chevron.right"
        }
    }

    var color: Color {
        switch self {
        case .clock: .blue
        case .date: .red
        case .commits: .green
        case .language: .purple
        }
    }
}
