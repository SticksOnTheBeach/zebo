import CoreGraphics
import Foundation
import Observation

/// État partagé entre AppKit (les fenêtres) et SwiftUI (le dessin).
@MainActor
@Observable
public final class NotchModel {
    /// Largeur ajoutée de chaque côté de l'encoche pour que la notch de Zebo dépasse un peu.
    public static let wingWidth: CGFloat = 36
    /// Rayon des petits arrondis concaves en haut de la notch.
    public nonisolated static let topCornerRadius: CGFloat = 6

    public var isOpen = false
    /// Taille de la notch fermée : l'encoche physique + les ailes.
    public var closedSize: CGSize = .zero
    public let openSize = CGSize(width: 480, height: 180)

    /// Cadre de la fenêtre de la notch et position de la souris, en coordonnées écran.
    public var panelFrame: CGRect = .zero
    public var mouseLocation: CGPoint = .zero
    /// Écran qui porte la notch (là où Zebo peut tomber).
    public var screenFrame: CGRect = .zero

    public init() {}

    /// Taille visible de la notch.
    public var notchSize: CGSize { isOpen ? openSize : closedSize }

    /// Place de Zebo dans la notch (origine en haut à gauche de la notch) :
    /// petit dans l'aile gauche, grand à gauche une fois ouverte.
    public var zeboFrame: CGRect {
        let closedHeight = closedSize.height
        if isOpen {
            let side: CGFloat = 96
            let y = closedHeight + (openSize.height - closedHeight - side) / 2
            return CGRect(x: 32, y: y, width: side, height: side)
        } else {
            let side: CGFloat = 22
            return CGRect(
                x: Self.topCornerRadius + 4, y: (closedHeight - side) / 2,
                width: side, height: side)
        }
    }

    /// Centre de Zebo en coordonnées écran, pour savoir dans quelle direction regarder.
    public var zeboScreenCenter: CGPoint {
        // La notch est centrée en haut de la fenêtre.
        let notchMinX = panelFrame.midX - notchSize.width / 2
        return CGPoint(
            x: notchMinX + zeboFrame.midX,
            y: panelFrame.maxY - zeboFrame.midY)
    }
}
