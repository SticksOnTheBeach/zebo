import SwiftUI

/// Un bouton qu'on clique, ou dont on maintient la touche : pendant l'appui, un contour se dessine
/// tout autour ; une fois le tour fait, c'est décidé.
struct HoldToConfirmButton: View {
    let title: String
    /// La touche à maintenir, affichée sur le bouton.
    let key: String
    /// La touche est enfoncée en ce moment.
    let isHeld: Bool
    let holdDuration: Duration
    var isProminent = false
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Text(key)
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(isProminent ? ZeboPalette.ink : .white)
                    .frame(width: 18, height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isProminent ? .white.opacity(0.55) : .white.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(isProminent ? ZeboPalette.ink.opacity(0.25) : .white.opacity(0.2))
                    )
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isProminent ? ZeboPalette.ink : .white)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
            )
            .scaleEffect(isHeld ? 0.96 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        // Le contour qui se dessine pendant qu'on maintient la touche.
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .trim(from: 0, to: progress)
                .stroke(
                    isProminent ? ZeboPalette.cloudBottom : .white,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .padding(-3.5)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHeld)
        .onChange(of: isHeld) {
            if isHeld {
                withAnimation(.linear(duration: Self.seconds(holdDuration))) { progress = 1 }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
            }
        }
    }

    private var background: Color {
        if isProminent { return isHovered ? ZeboPalette.cloudTop : ZeboPalette.cloudBottom }
        return isHovered ? ZeboPalette.buttonHovered : ZeboPalette.button
    }

    private static func seconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
