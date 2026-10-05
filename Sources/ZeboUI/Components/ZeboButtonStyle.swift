import AppKit
import SwiftUI

/// Bouton gris foncé aux coins légèrement arrondis, posé sur le noir de la notch.
/// Au survol, il s'éclaircit et grossit un peu (curseur en main) ; appuyé, il s'assombrit et se tasse.
struct ZeboButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZeboButton(configuration: configuration)
    }
}

private struct ZeboButton: View {
    let configuration: ButtonStyleConfiguration

    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(background)
            )
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    private var background: Color {
        if configuration.isPressed { return ZeboPalette.buttonPressed }
        return isHovered ? ZeboPalette.buttonHovered : ZeboPalette.button
    }

    private var scale: CGFloat {
        if configuration.isPressed { return 0.97 }
        return isHovered ? 1.03 : 1
    }
}
