import Testing

@testable import ZeboCore

@Suite("Répliques avec le prénom")
struct PersonalizedLinesTests {
    @Test("Le prénom remplace le marqueur")
    func nameIsInserted() {
        let lines = CannedLines.lines(name: "Mael")
        #expect(lines.contains { $0.contains("Mael") })
        #expect(!lines.contains { $0.contains(CannedLines.nameToken) })
    }

    @Test("Sans prénom, les répliques qui l'utilisent sont écartées")
    func linesWithoutNameAreDropped() {
        let lines = CannedLines.lines(name: "")
        #expect(!lines.isEmpty)
        #expect(!lines.contains { $0.contains(CannedLines.nameToken) })
    }

    @Test("Les répliques suivent les préférences")
    func linesFollowPreferences() {
        var preferences = ZeboPreferences.standard
        preferences.name = "Mael"
        let line = CannedLines(preferences: preferences).line(after: nil)
        #expect(CannedLines.lines(name: "Mael").contains(line))
    }
}
