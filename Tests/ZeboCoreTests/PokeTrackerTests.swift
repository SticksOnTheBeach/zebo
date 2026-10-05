import Foundation
import Testing

@testable import ZeboCore

@Suite("Règles des clics")
struct PokeTrackerTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    private func at(_ seconds: TimeInterval) -> Date {
        start.addingTimeInterval(seconds)
    }

    @Test("Le premier clic fait parler Zebo")
    func firstPokeSpeaks() {
        var tracker = PokeTracker()
        #expect(tracker.registerPoke(at: start) == .speak)
    }

    @Test("Un clic pendant le cooldown est ignoré")
    func pokeDuringCooldownIsIgnored() {
        var tracker = PokeTracker()
        _ = tracker.registerPoke(at: start)
        #expect(tracker.registerPoke(at: at(2)) == .ignore)
    }

    @Test("Après le cooldown, un clic relance un message")
    func pokeAfterCooldownSpeaks() {
        var tracker = PokeTracker()
        _ = tracker.registerPoke(at: start)
        #expect(tracker.registerPoke(at: at(4.1)) == .speak)
    }

    @Test("Trois clics en moins de 1,5 s l'assomment")
    func threeQuickPokesFaint() {
        var tracker = PokeTracker()
        _ = tracker.registerPoke(at: start)
        _ = tracker.registerPoke(at: at(0.5))
        #expect(tracker.registerPoke(at: at(1)) == .faint)
    }

    @Test("Des clics trop espacés ne l'assomment pas")
    func slowPokesDoNotFaint() {
        var tracker = PokeTracker()
        _ = tracker.registerPoke(at: start)
        _ = tracker.registerPoke(at: at(1))
        #expect(tracker.registerPoke(at: at(2)) == .ignore)
    }

    @Test("Après l'évanouissement, le compteur de clics repart de zéro")
    func faintResetsClickCount() {
        var tracker = PokeTracker()
        _ = tracker.registerPoke(at: start)
        _ = tracker.registerPoke(at: at(0.2))
        _ = tracker.registerPoke(at: at(0.4))
        #expect(tracker.registerPoke(at: at(0.6)) != .faint)
    }

    @Test("Un message lancé ailleurs déclenche aussi le cooldown")
    func notedMessageStartsCooldown() {
        var tracker = PokeTracker()
        tracker.noteMessage(at: start)
        #expect(tracker.registerPoke(at: at(1)) == .ignore)
    }
}
