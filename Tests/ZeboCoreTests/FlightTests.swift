import CoreGraphics
import Foundation
import Testing

@testable import ZeboCore

@Suite("Trajectoire de chute")
struct FlightTests {
    private let flight = Flight(
        start: .distantPast,
        origin: CGPoint(x: 100, y: 50),
        velocity: CGVector(dx: 200, dy: -640),
        size: 96,
        spinSpeed: 500,
        floorY: 900
    )

    @Test("Part de son point d'origine")
    func startsAtOrigin() {
        #expect(flight.position(at: 0) == CGPoint(x: 100, y: 50))
    }

    @Test("Avance sur le côté à vitesse constante")
    func movesSidewaysAtConstantSpeed() {
        let expected: CGFloat = 100 + 200 * 2
        #expect(flight.position(at: 2).x == expected)
    }

    @Test("Monte, puis retombe")
    func goesUpThenFalls() {
        let apexTime = 640 / Double(Flight.gravity)
        #expect(flight.position(at: apexTime).y < flight.origin.y)
        #expect(flight.position(at: apexTime * 3).y > flight.position(at: apexTime).y)
    }

    @Test("Se termine quand Zebo est entièrement sous l'écran")
    func durationEndsBelowScreen() {
        let bottom = flight.position(at: flight.duration).y
        #expect(abs(bottom - (flight.floorY + flight.size)) < 0.001)
    }

    @Test("S'efface pendant la seconde moitié de la chute")
    func fadesOutDuringSecondHalf() {
        #expect(flight.opacity(at: 0) == 1)
        #expect(flight.opacity(at: flight.floorY * 0.7) > 0)
        #expect(flight.opacity(at: flight.floorY * 0.7) < 1)
        #expect(flight.opacity(at: flight.floorY) == 0)
    }
}

@Suite("Éjection hors de la notch")
struct FlightEjectionTests {
    /// Générateur déterministe (SplitMix64) pour des tests reproductibles.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    private let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)

    @Test("Part du centre de Zebo, converti en coordonnées de la fenêtre de chute")
    func originIsConvertedToTopLeftCoordinates() {
        var generator = SeededGenerator(state: 1)
        let flight = Flight.ejection(from: CGPoint(x: 700, y: 900), in: screen, size: 96, using: &generator)
        #expect(flight.origin == CGPoint(x: 700, y: 82))
    }

    @Test("Est toujours catapulté vers le haut", arguments: 0..<20)
    func isAlwaysLaunchedUpwards(seed: UInt64) {
        var generator = SeededGenerator(state: seed)
        let flight = Flight.ejection(from: CGPoint(x: 700, y: 900), in: screen, size: 96, using: &generator)
        #expect(flight.velocity.dy < 0)
        #expect(abs(flight.velocity.dx) >= 180)
    }

    @Test("Tourne dans le sens où il part", arguments: 0..<20)
    func spinsTowardsItsDirection(seed: UInt64) {
        var generator = SeededGenerator(state: seed)
        let flight = Flight.ejection(from: CGPoint(x: 700, y: 900), in: screen, size: 96, using: &generator)
        #expect((flight.velocity.dx > 0) == (flight.spinSpeed > 0))
    }
}
