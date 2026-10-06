import CoreGraphics
import Foundation
import Observation

/// Les onglets de la notch ouverte.
public enum NotchTab: String, CaseIterable, Sendable {
    case home
    case projects
    /// La discussion avec Zebo (et l'IA choisie).
    case ai
}

/// État partagé entre AppKit (les fenêtres) et SwiftUI (le dessin).
@MainActor
@Observable
public final class NotchModel {
    /// Largeur ajoutée de chaque côté de l'encoche : à gauche le lit de Zebo, à droite l'heure.
    public static let wingWidth: CGFloat = 46
    /// Rayon des petits arrondis concaves en haut de la notch.
    public nonisolated static let topCornerRadius: CGFloat = 6

    public var isOpen = false
    /// L'onglet affiché quand la notch est ouverte.
    public var selectedTab: NotchTab = .home
    /// La souris survole la notch fermée : elle grandit un peu, en attendant un clic pour s'ouvrir.
    public var isPeeking = false
    /// De combien la notch fermée grandit au survol.
    public static let peekGrowth = CGSize(width: 16, height: 6)
    /// Taille de l'encoche physique (ou de la fausse notch si l'écran n'en a pas).
    public var hardwareNotchSize: CGSize = .zero
    /// On écrit dans la notch : elle reste ouverte même si la souris s'en va.
    public var isTyping = false
    /// Taille de la notch ouverte.
    public static let standardOpenSize = CGSize(width: 480, height: 180)
    /// Plus grande sur l'onglet IA, pour la discussion.
    public static let chatOpenSize = CGSize(width: 580, height: 240)
    /// La plus grande taille ouverte : celle de la fenêtre de la notch.
    public static var largestOpenSize: CGSize {
        CGSize(
            width: max(standardOpenSize.width, chatOpenSize.width),
            height: max(standardOpenSize.height, chatOpenSize.height))
    }

    /// Taille de la notch ouverte, selon l'onglet.
    public var openSize: CGSize { selectedTab == .ai ? Self.chatOpenSize : Self.standardOpenSize }

    /// Cadre de la fenêtre de la notch et position de la souris, en coordonnées écran.
    public var panelFrame: CGRect = .zero
    public var mouseLocation: CGPoint = .zero
    /// Écran qui porte la notch (là où Zebo peut tomber).
    public var screenFrame: CGRect = .zero

    public init() {}

    /// Taille de la notch fermée : l'encoche physique + les ailes.
    public var closedSize: CGSize {
        CGSize(width: hardwareNotchSize.width + Self.wingWidth * 2, height: hardwareNotchSize.height)
    }

    /// Taille de la notch survolée : un peu plus grande que fermée.
    public var peekSize: CGSize {
        CGSize(width: closedSize.width + Self.peekGrowth.width, height: closedSize.height + Self.peekGrowth.height)
    }

    /// Taille visible de la notch.
    public var notchSize: CGSize {
        if isOpen { return openSize }
        return isPeeking ? peekSize : closedSize
    }

    /// Place de Zebo dans la notch (origine en haut à gauche de la notch) :
    /// couché dans son lit dans l'aile gauche, grand à gauche une fois ouverte.
    public var zeboFrame: CGRect {
        let closedHeight = closedSize.height
        if isOpen {
            // Sous l'encoche physique, centré dans la place restante.
            let side: CGFloat = 96
            let top = hardwareNotchSize.height
            let y = top + (openSize.height - top - side) / 2
            return CGRect(x: 32, y: y, width: side, height: side)
        } else {
            // Toute l'aile gauche : le lit, vu de profil, est plus large que haut.
            // Un peu de marge à gauche pour que le coin arrondi du bas ne mange pas la tête de lit.
            let height = max(closedHeight - 4, 0)
            return CGRect(
                x: Self.topCornerRadius + 3, y: (closedHeight - height) / 2,
                width: Self.wingWidth - Self.topCornerRadius - 4, height: height)
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
