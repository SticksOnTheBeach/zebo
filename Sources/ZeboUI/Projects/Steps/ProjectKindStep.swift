import SwiftUI
import ZeboCore

/// Première étape d'un nouveau projet : son thème ou son langage.
struct ProjectKindStep: View {
    @Bindable var wizard: NewProjectWizard

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        SetupStepLayout(title: "On crée quoi ?", subtitle: "Choisis le thème ou le langage de ton nouveau projet.") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(ProjectKind.allCases.enumerated()), id: \.element) { index, kind in
                    SelectableTile(title: kind.name, isSelected: wizard.kind == kind) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { wizard.kind = kind }
                    } icon: {
                        CodeLogo(kind: kind)
                    }
                    .appearing(order: 2 + index % 5)
                }
            }
        }
    }
}
