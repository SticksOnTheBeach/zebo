import SwiftUI

extension EnvironmentValues {
    /// Tout s'affiche directement, sans animation d'apparition (aperçus, captures).
    @Entry var showsFinalAppearance = false
}

extension View {
    /// L'élément arrive en fondu en remontant un peu, après ceux d'avant :
    /// `order` 0 en premier, puis chaque rang un peu plus tard.
    func appearing(order: Int) -> some View {
        modifier(Appearing(order: order))
    }
}

private struct Appearing: ViewModifier {
    let order: Int

    @Environment(\.showsFinalAppearance) private var showsFinalAppearance
    @State private var hasAppeared = false

    private var isVisible: Bool { hasAppeared || showsFinalAppearance }

    /// Délai entre deux rangs.
    private static let stagger = 0.06
    /// Délai avant le premier : le temps que l'étape précédente commence à partir.
    private static let initialDelay = 0.12

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 14)
            .onAppear {
                let delay = Self.initialDelay + Double(order) * Self.stagger
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}
