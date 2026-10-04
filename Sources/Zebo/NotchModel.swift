import Foundation
import Observation

/// État partagé entre AppKit (la fenêtre) et SwiftUI (le dessin).
@MainActor
@Observable
final class NotchModel {
    var isOpen = false
    /// Taille de la notch fermée : l'encoche physique + les ailes.
    var closedSize: CGSize = .zero
    let openSize = CGSize(width: 480, height: 180)

    /// Cadre de la fenêtre de la notch et position de la souris, en coordonnées écran.
    var panelFrame: CGRect = .zero
    var mouseLocation: CGPoint = .zero

    /// Taille visible de la notch.
    var notchSize: CGSize { isOpen ? openSize : closedSize }

    /// Place de Zebo dans la notch (origine en haut à gauche de la notch) :
    /// petit dans l'aile gauche, grand à gauche une fois ouverte.
    var zeboFrame: CGRect {
        let closedHeight = closedSize.height
        if isOpen {
            let side: CGFloat = 96
            let y = closedHeight + (openSize.height - closedHeight - side) / 2
            return CGRect(x: 32, y: y, width: side, height: side)
        } else {
            let side: CGFloat = 22
            return CGRect(x: NotchShape.topRadius + 4, y: (closedHeight - side) / 2,
                          width: side, height: side)
        }
    }

    /// Centre de Zebo en coordonnées écran, pour savoir dans quelle direction regarder.
    var zeboScreenCenter: CGPoint {
        // La notch est centrée en haut de la fenêtre.
        let notchMinX = panelFrame.midX - notchSize.width / 2
        return CGPoint(x: notchMinX + zeboFrame.midX,
                       y: panelFrame.maxY - zeboFrame.midY)
    }
}
