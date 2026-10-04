import AppKit
import SwiftUI

/// Fenêtre sans bordure, transparente, posée par-dessus la barre des menus à l'emplacement de l'encoche.
/// Elle a la taille de la notch ouverte ; le dessin SwiftUI gère la taille visible.
final class NotchPanel: NSPanel {
    /// Largeur ajoutée de chaque côté de l'encoche pour que la notch de Zebo dépasse un peu.
    static let wingWidth: CGFloat = 36

    init(model: NotchModel) {
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
        // Fermée au démarrage : les clics passent au travers.
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true
        // Au-dessus de la barre des menus.
        level = .mainMenu + 3
        // Visible sur tous les bureaux et par-dessus les apps en plein écran.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        contentView = NSHostingView(rootView: NotchView(model: model))
    }

    // Nécessaire plus tard pour pouvoir taper dans le champ de discussion.
    override var canBecomeKey: Bool { true }
}
