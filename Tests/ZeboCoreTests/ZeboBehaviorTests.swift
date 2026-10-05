import CoreGraphics
import Testing

@testable import ZeboCore

@MainActor
@Suite("Comportement de Zebo")
struct ZeboBehaviorTests {
    private final class SpeechSpy: ZeboSpeaking {
        var randomLines = 0
        var spokenLines: [String] = []
        var silences = 0

        func sayRandom() { randomLines += 1 }
        func say(_ text: String) { spokenLines.append(text) }
        func silence() { silences += 1 }
    }

    private final class FixedPlacement: ZeboPlacement {
        let zeboScreenCenter = CGPoint(x: 700, y: 900)
        let zeboFrame = CGRect(x: 32, y: 40, width: 96, height: 96)
        let screenFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)
    }

    private let speech = SpeechSpy()
    private let behavior: ZeboBehavior

    init() {
        behavior = ZeboBehavior(placement: FixedPlacement(), speech: speech)
    }

    @Test("Un clic le fait parler")
    func pokeMakesHimSpeak() {
        behavior.poke()
        #expect(speech.randomLines == 1)
        #expect(behavior.state == .normal)
    }

    @Test("Trois clics rapides l'assomment")
    func quickPokesMakeHimDizzy() {
        behavior.poke()
        behavior.poke()
        behavior.poke()
        #expect(behavior.state == .dizzy)
        #expect(speech.spokenLines == ["Ouuuh… je vois des étoiles…"])
        #expect(behavior.isHome)
    }

    @Test("Sonné, il ne réagit plus aux clics")
    func ignoresPokesWhileDizzy() {
        for _ in 0..<3 { behavior.poke() }
        behavior.poke()
        #expect(speech.randomLines == 1)
    }

    @Test("Un deuxième clic pendant le cooldown ne relance pas de message")
    func secondPokeDuringCooldownIsIgnored() {
        behavior.poke()
        behavior.poke()
        #expect(speech.randomLines == 1)
        #expect(behavior.state == .normal)
    }

    @Test("Assommé, il finit par être éjecté de la notch")
    func faintingEndsWithAnEjection() async {
        var flightChanges: [Bool] = []
        behavior.onFlightChange = { flightChanges.append($0) }
        for _ in 0..<3 { behavior.poke() }

        #expect(await waitUntil(timeout: .seconds(3)) { behavior.state == .flying })
        #expect(behavior.flight != nil)
        #expect(!behavior.isHome)
        #expect(flightChanges == [true])
        // Il se tait au moment d'être catapulté.
        #expect(speech.silences == 1)
    }
}
