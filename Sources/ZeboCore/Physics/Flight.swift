import CoreGraphics
import Foundation

/// Trajectoire de Zebo éjecté : un lancer avec gravité, qui tourne sur lui-même.
public struct Flight: Sendable {
    public static let gravity: CGFloat = 2200

    public let start: Date
    /// Point de départ, dans la fenêtre plein écran (origine en haut à gauche).
    public let origin: CGPoint
    /// Vitesse initiale en points/s (dy < 0 = vers le haut).
    public let velocity: CGVector
    public let size: CGFloat
    /// Vitesse de rotation en degrés/s.
    public let spinSpeed: Double
    /// Hauteur de l'écran.
    public let floorY: CGFloat

    public init(
        start: Date,
        origin: CGPoint,
        velocity: CGVector,
        size: CGFloat,
        spinSpeed: Double,
        floorY: CGFloat
    ) {
        self.start = start
        self.origin = origin
        self.velocity = velocity
        self.size = size
        self.spinSpeed = spinSpeed
        self.floorY = floorY
    }

    /// Zebo catapulté hors de la notch, vers le haut et d'un côté pris au hasard.
    /// - Parameters:
    ///   - center: centre de Zebo en coordonnées écran (origine en bas à gauche).
    ///   - screen: cadre de l'écran où il tombe.
    public static func ejection(
        from center: CGPoint,
        in screen: CGRect,
        size: CGFloat,
        start: Date = Date(),
        using generator: inout some RandomNumberGenerator
    ) -> Flight {
        let direction: CGFloat = Bool.random(using: &generator) ? 1 : -1
        return Flight(
            start: start,
            // Coordonnées de la fenêtre de chute (plein écran, origine en haut à gauche).
            origin: CGPoint(x: center.x - screen.minX, y: screen.maxY - center.y),
            velocity: CGVector(dx: direction * .random(in: 180...320, using: &generator), dy: -640),
            size: size,
            spinSpeed: Double(direction) * .random(in: 380...620, using: &generator),
            floorY: screen.height
        )
    }

    public func position(at t: Double) -> CGPoint {
        let t = CGFloat(t)
        return CGPoint(x: origin.x + velocity.dx * t,
                       y: origin.y + velocity.dy * t + 0.5 * Self.gravity * t * t)
    }

    /// Temps pour sortir par le bas de l'écran.
    public var duration: Double {
        let distance = floorY + size - origin.y
        let v = velocity.dy
        return Double((-v + sqrt(v * v + 2 * Self.gravity * distance)) / Self.gravity)
    }

    /// Il s'efface pendant la seconde moitié de la chute.
    public func opacity(at y: CGFloat) -> Double {
        Double(max(0, min(1, 1 - (y - floorY * 0.45) / (floorY * 0.5))))
    }
}
