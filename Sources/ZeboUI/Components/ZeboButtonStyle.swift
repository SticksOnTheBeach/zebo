import AppKit
import SwiftUI

/// Bouton aux coins légèrement arrondis, posé sur du noir.
/// Au survol, il s'éclaircit et grossit un peu (curseur en main) ; appuyé, il s'assombrit et se tasse.
struct ZeboButtonStyle: ButtonStyle {
    enum Kind {
        /// Gris foncé, texte blanc.
        case secondary
        /// Blanc, texte noir : l'action principale.
        case primary
    }

    enum Shape {
        /// Un texte, éventuellement avec une icône.
        case text
        /// Une icône seule, dans un carré.
        case icon
    }

    var kind: Kind = .secondary
    var shape: Shape = .text

    func makeBody(configuration: Configuration) -> some View {
        ZeboButton(configuration: configuration, kind: kind, shape: shape)
    }
}

private struct ZeboButton: View {
    let configuration: ButtonStyleConfiguration
    let kind: ZeboButtonStyle.Kind
    let shape: ZeboButtonStyle.Shape

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, shape == .icon ? 0 : 14)
            .padding(.vertical, shape == .icon ? 0 : 7)
            .frame(width: shape == .icon ? 36 : nil, height: shape == .icon ? 36 : nil)
            .background(
                RoundedRectangle(cornerRadius: shape == .icon ? 10 : 8, style: .continuous)
                    .fill(background)
            )
            .contentShape(Rectangle())
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.2), value: isEnabled)
            .onHover { hovering in
                isHovered = hovering && isEnabled
                if hovering, isEnabled {
                    NSCursor.pointingHand.push()
                } else if !hovering {
                    NSCursor.pop()
                }
            }
    }

    private var foreground: Color {
        guard isEnabled else { return .white.opacity(0.3) }
        return kind == .primary ? .black : .white
    }

    private var background: Color {
        guard isEnabled else { return ZeboPalette.buttonDisabled }
        switch kind {
        case .secondary:
            if configuration.isPressed { return ZeboPalette.buttonPressed }
            return isHovered ? ZeboPalette.buttonHovered : ZeboPalette.button
        case .primary:
            if configuration.isPressed { return Color(white: 0.75) }
            return isHovered ? Color(white: 0.88) : .white
        }
    }

    private var scale: CGFloat {
        if configuration.isPressed { return 0.97 }
        return isHovered ? 1.03 : 1
    }
}
