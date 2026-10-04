import AppKit
import SwiftUI

/// Fenêtre sans bordure, transparente, posée par-dessus la barre des menus à l'emplacement de l'encoche.
final class NotchPanel: NSPanel {
    /// Largeur ajoutée de chaque côté de l'encoche pour que la notch de Zebo dépasse un peu.
    static let wingWidth: CGFloat = 36

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        // Au-dessus de la barre des menus.
        level = .mainMenu + 3
        // Visible sur tous les bureaux et par-dessus les apps en plein écran.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        contentView = NSHostingView(rootView: NotchView())
    }

    // Nécessaire plus tard pour pouvoir taper dans le champ de discussion.
    override var canBecomeKey: Bool { true }

    func reposition() {
        guard let screen = NSScreen.notchScreen else { return }
        let notch = screen.notchSize
        let size = CGSize(width: notch.width + Self.wingWidth * 2, height: notch.height)
        let origin = CGPoint(x: screen.frame.midX - size.width / 2,
                             y: screen.frame.maxY - size.height)
        setFrame(CGRect(origin: origin, size: size), display: true)
    }
}
