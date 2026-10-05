import SwiftUI

/// Dans la notch ouverte, tant que Zebo n'est pas configuré : une phrase et le bouton « Configurer ».
struct SetupPrompt: View {
    var onConfigure: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Salut, moi c'est Zebo !")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Avant qu'on commence, il faut me configurer.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Button(action: onConfigure) {
                Label("Configurer Zebo", systemImage: "sparkles")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(ZeboPalette.button))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}
