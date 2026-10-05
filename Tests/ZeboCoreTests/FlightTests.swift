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
