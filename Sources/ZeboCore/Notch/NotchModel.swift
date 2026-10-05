import CoreGraphics
import Foundation
import Observation

/// État partagé entre AppKit (les fenêtres) et SwiftUI (le dessin).
@MainActor
@Observable
public final class NotchModel {
    /// Largeur ajoutée de chaque côté de l'encoche ; l'heure s'affiche dans l'aile droite.
    public static let wingWidth: CGFloat = 46
    /// Bandeau ajouté sous l'encoche physique quand la notch est fermée : Zebo y dort,
    /// au milieu (l'encoche elle-même n'a pas de pixels).
    public static let sleepBandHeight: CGFloat = 26
    /// Rayon des petits arrondis concaves en haut de la notch.
    public nonisolated static let topCornerRadius: CGFloat = 6

    public var isOpen = false
    /// Taille de l'encoche physique (ou de la fausse notch si l'écran n'en a pas).
    public var hardwareNotchSize: CGSize = .zero
    public let openSize = CGSize(width: 480, height: 180)

    /// Cadre de la fenêtre de la notch et position de la souris, en coordonnées écran.
    public var panelFrame: CGRect = .zero
    public var mouseLocation: CGPoint = .zero
    /// Écran qui porte la notch (là où Zebo peut tomber).
    public var screenFrame: CGRect = .zero

    public init() {}

    /// Taille de la notch fermée : l'encoche physique, les ailes, et le bandeau du dessous.
    public var closedSize: CGSize {
        CGSize(
            width: hardwareNotchSize.width + Self.wingWidth * 2,
            height: hardwareNotchSize.height + Self.sleepBandHeight)
    }

    /// Taille visible de la notch.
    public var notchSize: CGSize { isOpen ? openSize : closedSize }

    /// Place de Zebo dans la notch (origine en haut à gauche de la notch) :
    /// couché dans son lit au milieu du bandeau, grand à gauche une fois ouverte.
    public var zeboFrame: CGRect {
        // Juste sous l'encoche physique, centré dans la place restante.
        let top = hardwareNotchSize.height
        if isOpen {
            let side: CGFloat = 96
            return CGRect(x: 32, y: top + (openSize.height - top - side) / 2, width: side, height: side)
        } else {
            // Le lit, vu de profil, est plus large que haut.
            let height = max(Self.sleepBandHeight - 3, 0)
            let width = height * 2
            return CGRect(
                x: (closedSize.width - width) / 2, y: top + (Self.sleepBandHeight - height) / 2,
                width: width, height: height)
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
