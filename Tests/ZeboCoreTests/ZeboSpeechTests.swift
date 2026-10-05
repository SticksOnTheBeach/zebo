import Testing

@testable import ZeboCore

@MainActor
@Suite("Parole de Zebo")
struct ZeboSpeechTests {
    /// Source de répliques qui note ce qu'on lui demande et renvoie toujours la même phrase.
    private final class FixedLines: SpeechLineSource, @unchecked Sendable {
        private(set) var previousLines: [String?] = []
        let next: String

        init(next: String) { self.next = next }

        func line(after previous: String?) -> String {
            previousLines.append(previous)
            return next
        }
    }

    @Test("Au repos, Zebo ne dit rien")
    func silentByDefault() {
        let speech = ZeboSpeech()
        #expect(speech.line == nil)
        #expect(speech.revealedCount == 0)
        #expect(speech.lineID == 0)
    }

    @Test("Une nouvelle réplique s'affiche à partir de zéro caractère")
    func sayStartsANewLine() {
        let speech = ZeboSpeech()
        speech.say("Coucou")
        #expect(speech.line == "Coucou")
        #expect(speech.revealedCount == 0)
        #expect(speech.lineID == 1)
    }

    @Test("Chaque réplique change d'identifiant, pour faire sauter Zebo")
    func eachLineHasANewID() {
        let speech = ZeboSpeech()
        speech.say("Un")
        speech.say("Deux")
        #expect(speech.lineID == 2)
        #expect(speech.line == "Deux")
    }

    @Test("Le texte se révèle lettre par lettre jusqu'au bout")
    func revealsTheWholeLine() async {
        let speech = ZeboSpeech()
        speech.say("abc")
        #expect(await waitUntil { speech.revealedCount == 3 })
        #expect(speech.line == "abc")
    }

    @Test("Couper la parole fait disparaître la bulle tout de suite")
    func silenceClearsTheLine() async {
        let speech = ZeboSpeech()
        speech.say("Une longue phrase")
        speech.silence()
        #expect(speech.line == nil)
        // La machine à écrire est arrêtée : plus rien ne s'affiche.
        try? await Task.sleep(for: .milliseconds(100))
        #expect(speech.revealedCount == 0)
    }

    @Test("Une réplique au hasard vient de la source, qui connaît la précédente")
    func sayRandomAsksTheLineSource() {
        let source = FixedLines(next: "Salut")
        let speech = ZeboSpeech(lineSource: source)
        speech.say("Avant")
        speech.sayRandom()
        #expect(speech.line == "Salut")
        #expect(source.previousLines == ["Avant"])
    }
}
