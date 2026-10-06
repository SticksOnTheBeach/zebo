import SwiftUI
import ZeboCore

/// Les onglets de la notch ouverte, en colonne sur sa droite ; la pastille glisse sous l'onglet
/// choisi. En bas, les paramètres (qui s'ouvrent dans leur propre fenêtre).
struct NotchTabBar: View {
    @Binding var selection: NotchTab
    let onOpenSettings: () -> Void

    @Namespace private var pill

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(NotchTab.allCases, id: \.self) { tab in
                item(tab.title, symbol: tab.symbol, isSelected: selection == tab) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = tab }
                }
            }
            Spacer(minLength: 4)
            item("Paramètres", symbol: "gearshape.fill", isSelected: false, action: onOpenSettings)
        }
    }

    private func item(_ title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected ? 1 : 0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.14))
                            .matchedGeometryEffect(id: "pill", in: pill)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension NotchTab {
    var title: String {
        switch self {
        case .home: "Accueil"
        case .projects: "Projets"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .projects: "folder.fill"
        }
    }
}
