import Foundation
import Testing

@testable import ZeboCore

@MainActor
@Suite("Commits du jour")
struct CommitActivityTests {
    private struct FixedCounter: CommitCounter {
        let count: Int?
        func commitsToday(in folder: URL) async -> Int? { count }
    }

    @Test("Avant de compter, on ne sait pas")
    func unknownAtFirst() {
        #expect(CommitActivity(counter: FixedCounter(count: 3)).todayCount == nil)
    }

    @Test("Après avoir compté, on connaît le nombre de commits")
    func refreshCounts() async {
        let activity = CommitActivity(counter: FixedCounter(count: 7))
        await activity.refresh(in: URL(fileURLWithPath: "/tmp"))
        #expect(activity.todayCount == 7)
    }

    @Test("Le dossier de projets est le premier qui existe")
    func guessesFirstExistingFolder() {
        let home = URL(fileURLWithPath: "/Users/me")
        let existing: Set<String> = ["/Users/me/Projects", "/Users/me/Code"]
        let folder = ProjectsFolder.guess(home: home) { existing.contains($0.path) }
        #expect(folder?.path == "/Users/me/Projects")
    }

    @Test("Sans dossier de projets connu, on ne devine rien")
    func noFolderToGuess() {
        #expect(ProjectsFolder.guess(home: URL(fileURLWithPath: "/Users/me")) { _ in false } == nil)
    }
}
