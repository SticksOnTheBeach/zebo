import Testing

@testable import ZeboCore

@Suite("Répliques toutes faites")
struct CannedLinesTests {
    @Test("Ne répète jamais deux fois de suite la même réplique")
    func neverRepeatsPreviousLine() {
        let source = CannedLines(["A", "B", "C"])
        for _ in 0..<100 {
            #expect(source.line(after: "A") != "A")
        }
    }

    @Test("Avec une seule réplique, la redit quand même")
    func singleLineIsRepeated() {
        let source = CannedLines(["Seule"])
        #expect(source.line(after: "Seule") == "Seule")
    }

    @Test("Pioche toujours dans sa liste")
    func picksFromItsLines() {
        let lines = ["A", "B"]
        let source = CannedLines(lines)
        #expect(lines.contains(source.line(after: nil)))
    }
}
