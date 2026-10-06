import SwiftUI
import ZeboCore

/// Deuxième étape : le nom du projet (et donc de son dossier).
struct ProjectNameStep: View {
    @Bindable var wizard: NewProjectWizard

    @FocusState private var isFocused: Bool

    var body: some View {
        SetupStepLayout(
            title: "Comment s'appelle-t-il ?",
            subtitle: "C'est aussi le nom de son dossier. Je te montre où je le range juste après."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                TextField("", text: $wizard.name, prompt: Text("Mon super projet").foregroundStyle(.white.opacity(0.3)))
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .focused($isFocused)
                    .onSubmit(wizard.advance)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: 420)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.25)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isFocused ? ZeboPalette.cloudBottom : .white.opacity(0.1), lineWidth: isFocused ? 2 : 1)
                    )
                    .animation(.easeOut(duration: 0.2), value: isFocused)
                    .appearing(order: 2)

                if !wizard.name.isEmpty, !ProjectScaffolder.isValidName(wizard.name) {
                    Label(
                        "Pas de « / » ni de « : », et pas de point au début.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange)
                    .transition(.opacity.combined(with: .offset(y: -6)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: ProjectScaffolder.isValidName(wizard.name))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isFocused = true }
        }
    }
}
