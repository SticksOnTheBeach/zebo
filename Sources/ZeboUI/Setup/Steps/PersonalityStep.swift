import SwiftUI
import ZeboCore

/// Troisième étape : la façon de parler de Zebo, avec un exemple de ce qu'il dirait.
struct PersonalityStep: View {
    @Bindable var wizard: SetupWizard

    var body: some View {
        SetupStepLayout(
            title: "Je suis plutôt…",
            subtitle: "Choisis ma façon de te parler. Tu pourras changer d'avis."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    ForEach(Array(Personality.allCases.enumerated()), id: \.element) { index, personality in
                        PersonalityCard(
                            personality: personality,
                            isSelected: wizard.draft.personality == personality
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                wizard.draft.personality = personality
                            }
                        }
                        .appearing(order: 2 + index)
                    }
                }

                sample
                    .appearing(order: 5)
            }
        }
    }

    /// Ce que dirait Zebo avec cette personnalité.
    private var sample: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(wizard.draft.personality.color)
            Text(CannedLines.sample(for: wizard.draft.personality, name: wizard.trimmedName))
                .font(.system(size: 15, design: .rounded))
                .italic()
                .foregroundStyle(.white.opacity(0.85))
                .id(wizard.draft.personality)
                .transition(.opacity.combined(with: .offset(y: 6)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
    }
}

/// Une carte de personnalité : icône, nom et description ; cochée quand elle est choisie.
private struct PersonalityCard: View {
    let personality: Personality
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: personality.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(personality.color)
            Text(personality.title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(personality.detail)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: isSelected ? 0.17 : (isHovered ? 0.13 : 0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isSelected ? personality.color : .white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(personality.color)
                    .padding(12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
