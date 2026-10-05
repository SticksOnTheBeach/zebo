import SwiftUI
import ZeboCore

/// Comment présenter chaque personnalité de Zebo.
extension Personality {
    var title: String {
        switch self {
        case .gentle: "Doux"
        case .playful: "Taquin"
        case .zen: "Zen"
        }
    }

    var detail: String {
        switch self {
        case .gentle: "Des petits mots gentils et des encouragements."
        case .playful: "Il te charrie un peu, mais avec amour."
        case .zen: "Calme, il t'aide à souffler et à faire des pauses."
        }
    }

    var symbol: String {
        switch self {
        case .gentle: "heart.fill"
        case .playful: "face.smiling.inverse"
        case .zen: "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .gentle: .pink
        case .playful: .orange
        case .zen: .green
        }
    }
}
