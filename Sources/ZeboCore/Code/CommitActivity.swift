import Foundation
import Observation

/// Compte les commits faits aujourd'hui dans les dépôts Git d'un dossier.
public protocol CommitCounter: Sendable {
    /// `nil` si on n'a pas pu compter (Git absent, dossier introuvable…).
    func commitsToday(in folder: URL) async -> Int?
}

/// Le nombre de commits du jour, affiché dans la notch.
@MainActor
@Observable
public final class CommitActivity {
    /// `nil` tant qu'on n'a pas compté (ou si on n'a pas pu).
    public private(set) var todayCount: Int?

    @ObservationIgnored private let counter: any CommitCounter

    public init(counter: any CommitCounter) {
        self.counter = counter
    }

    /// Recompte les commits du jour dans ce dossier.
    public func refresh(in folder: URL) async {
        todayCount = await counter.commitsToday(in: folder)
    }
}

/// Où l'on range d'habitude ses projets.
public enum ProjectsFolder {
    /// Dossiers essayés, dans l'ordre, depuis le dossier personnel.
    public static let candidates = [
        "Documents/Dev", "Developer", "Projects", "Code", "dev", "Documents/GitHub", "Documents/Projects",
    ]

    /// Le premier dossier de projets qui existe, s'il y en a un.
    public static func guess(home: URL, isDirectory: (URL) -> Bool) -> URL? {
        candidates.lazy.map { home.appending(path: $0) }.first(where: isDirectory)
    }
}
