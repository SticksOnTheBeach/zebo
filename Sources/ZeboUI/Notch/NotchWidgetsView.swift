import SwiftUI
import ZeboCore

/// L'aile droite de la notch fermée : un widget, ou plusieurs qui se relaient
/// (le suivant glisse depuis le bas).
struct NotchWidgetsView: View {
    let widgets: [NotchWidget]
    let interval: TimeInterval
    let language: Language?
    let commitCount: Int?

    var body: some View {
        if widgets.count > 1 {
            // Une vérification par seconde suffit pour changer de widget au bon moment.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                rotating(at: context.date)
            }
        } else {
            rotating(at: .now)
        }
    }

    private func rotating(at date: Date) -> some View {
        let current = NotchWidgetRotation.widget(among: widgets, every: interval, at: date)
        return ZStack {
            if let current {
                widget(current)
                    .id(current)
                    .transition(.push(from: .bottom))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: current)
        .clipped()
    }

    @ViewBuilder
    private func widget(_ widget: NotchWidget) -> some View {
        Group {
            switch widget {
            case .clock:
                NotchClock()
            case .date:
                TimelineView(.everyMinute) { context in
                    Text(context.date, format: .dateTime.day().month(.abbreviated))
                }
            case .commits:
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10, weight: .bold))
                    Text(commitCount.map(String.init) ?? "–")
                }
            case .language:
                if let language {
                    HStack(spacing: 3) {
                        CodeLogo(language: language, size: 11)
                        Text(language.shortName)
                    }
                }
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}
