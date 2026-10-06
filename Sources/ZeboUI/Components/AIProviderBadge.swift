import SwiftUI
import ZeboCore

/// L'emblème d'une IA : ses initiales sur sa couleur (pas de logo de marque embarqué).
struct AIProviderBadge: View {
    let provider: AIProvider
    var size: CGFloat = 38

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white))
    }

    private var color: Color {
        switch provider {
        case .claude: Color(red: 0.85, green: 0.47, blue: 0.34)
        case .openAI: Color(red: 0.06, green: 0.64, blue: 0.5)
        case .gemini: Color(red: 0.26, green: 0.52, blue: 0.96)
        case .mistral: Color(red: 0.98, green: 0.52, blue: 0.13)
        }
    }

    private var symbol: String {
        switch provider {
        case .claude: "asterisk"
        case .openAI: "circle.hexagongrid"
        case .gemini: "sparkle"
        case .mistral: "wind"
        }
    }
}
