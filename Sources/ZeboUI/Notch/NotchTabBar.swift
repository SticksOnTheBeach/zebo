import SwiftUI
import ZeboCore

/// Les onglets de la notch ouverte ; la pastille glisse sous l'onglet choisi.
struct NotchTabBar: View {
    @Binding var selection: NotchTab

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(NotchTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = tab }
                } label: {
                    Label(tab.title, systemImage: tab.symbol)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(selection == tab ? 1 : 0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            if selection == tab {
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
