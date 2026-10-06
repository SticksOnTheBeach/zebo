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
        /// Un grand bouton, large, pour l'action principale d'un écran (« Commencer »).
        case wide
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
            .font(.system(size: shape == .wide ? 15 : 13, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, shape == .text ? 14 : 0)
            .padding(.vertical, shape == .text ? 7 : 0)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: shape == .text ? 8 : 10, style: .continuous)
                    .fill(background)
            )
            .overlay(
                // Un fin liseré, pour que le bouton se détache du verre.
                RoundedRectangle(cornerRadius: shape == .text ? 8 : 10, style: .continuous)
                    .strokeBorder(.white.opacity(kind == .secondary ? 0.1 : 0))
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

    private var width: CGFloat? {
        switch shape {
        case .text: nil
        case .icon: 36
        case .wide: 260
        }
    }

    private var height: CGFloat? {
        switch shape {
        case .text: nil
        case .icon: 36
        case .wide: 42
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
