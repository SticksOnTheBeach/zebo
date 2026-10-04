import AppKit
import SwiftUI

/// Fenêtre sans bordure et transparente, posée par-dessus la barre des menus.
/// Sert à la notch et à la bulle de dialogue ; le dessin SwiftUI gère ce qui est visible.
final class OverlayPanel: NSPanel {
    init<Content: View>(rootView: Content) {
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
        // Par défaut les clics passent au travers.
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true
        // Au-dessus de la barre des menus.
        level = .mainMenu + 3
        // Visible sur tous les bureaux et par-dessus les apps en plein écran.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        contentView = NSHostingView(rootView: rootView)
    }

    // Nécessaire plus tard pour pouvoir taper dans le champ de discussion.
    override var canBecomeKey: Bool { true }
}
