import SwiftUI
import ZeboCore

/// Deuxième étape : comment Zebo doit t'appeler.
struct NameStep: View {
    @Bindable var wizard: SetupWizard

    @FocusState private var isFocused: Bool

    var body: some View {
        SetupStepLayout(
            title: "Comment je t'appelle ?",
            subtitle: "Ton prénom, ou un surnom : c'est toi qui choisis."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                field
                    .appearing(order: 2)

                if !wizard.trimmedName.isEmpty {
                    Text("Enchanté, \(wizard.trimmedName) ! 👋")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(ZeboPalette.cloudBottom)
                        .transition(.opacity.combined(with: .offset(y: -6)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: wizard.trimmedName.isEmpty)
        }
        .onAppear {
            // Le temps que l'étape arrive, puis on peut taper directement.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isFocused = true }
        }
    }

    private var field: some View {
        TextField(
            "", text: $wizard.draft.name,
            prompt: Text("Ton prénom").foregroundStyle(.white.opacity(0.3))
        )
        .textFieldStyle(.plain)
        .font(.system(size: 24, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .focused($isFocused)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 380)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(white: 0.12)))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFocused ? ZeboPalette.cloudBottom : .white.opacity(0.1), lineWidth: isFocused ? 2 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .onChange(of: wizard.draft.name) { _, name in
            if name.count > SetupWizard.maxNameLength {
                wizard.draft.name = String(name.prefix(SetupWizard.maxNameLength))
            }
        }
    }
}
