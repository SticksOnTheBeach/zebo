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
}
