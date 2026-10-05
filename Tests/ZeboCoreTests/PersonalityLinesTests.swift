import Testing

@testable import ZeboCore

@Suite("Répliques selon la personnalité")
struct PersonalityLinesTests {
    @Test("Le prénom remplace le marqueur", arguments: Personality.allCases)
    func nameIsInserted(personality: Personality) {
        let lines = CannedLines.lines(for: personality, name: "Mael")
        #expect(lines.contains { $0.contains("Mael") })
        #expect(!lines.contains { $0.contains(CannedLines.nameToken) })
    }

    @Test("Sans prénom, les répliques qui l'utilisent sont écartées", arguments: Personality.allCases)
    func linesWithoutNameAreDropped(personality: Personality) {
        let lines = CannedLines.lines(for: personality, name: "")
        #expect(!lines.isEmpty)
        #expect(!lines.contains { $0.contains(CannedLines.nameToken) })
    }

    @Test("Chaque personnalité a sa façon de parler")
    func personalitiesDiffer() {
        let samples = Personality.allCases.map { CannedLines.sample(for: $0, name: "Mael") }
        #expect(Set(samples).count == Personality.allCases.count)
    }

    @Test("Les répliques suivent les préférences")
    func linesFollowPreferences() {
        let preferences = ZeboPreferences(name: "Mael", personality: .zen, showsClock: true, sleepsWhenClosed: true)
        let line = CannedLines(preferences: preferences).line(after: nil)
        #expect(CannedLines.lines(for: .zen, name: "Mael").contains(line))
    }
}
