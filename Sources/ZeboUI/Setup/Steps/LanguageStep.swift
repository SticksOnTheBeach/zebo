import SwiftUI
import ZeboCore

/// Étape du langage préféré : une grille de langages, un seul choix (facultatif).
struct LanguageStep: View {
    @Bindable var wizard: SetupWizard

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        SetupStepLayout(
            title: "Ton langage préféré ?",
            subtitle: "Je pourrai l'afficher dans ta notch. Tu peux aussi passer."
        ) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(Language.allCases.enumerated()), id: \.element) { index, language in
                    LanguageTile(language: language, isSelected: wizard.draft.favoriteLanguage == language) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            // Recliquer sur le langage choisi le retire.
                            wizard.draft.favoriteLanguage =
                                wizard.draft.favoriteLanguage == language ? nil : language
                        }
                    }
                    .appearing(order: 2 + index % 6)
                }
            }
        }
    }
}

private struct LanguageTile: View {
    let language: Language
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 7) {
            CodeLogo(language: language)
                .scaleEffect(isSelected ? 1.08 : 1)
            Text(language.name)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: isSelected ? 0.17 : (isHovered ? 0.12 : 0.08)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? language.color : .white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(language.color)
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isHovered && !isSelected ? 1.04 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
