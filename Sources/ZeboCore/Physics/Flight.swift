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
