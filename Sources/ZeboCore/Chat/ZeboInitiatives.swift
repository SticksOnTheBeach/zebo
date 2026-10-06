import Foundation
import Observation

/// Les initiatives de Zebo : une action qu'il propose de lui-même, en plus de ce qu'on lui a demandé.
/// Une seule s'affiche à la fois ; on l'accepte ou la refuse d'un clic, ou en maintenant Y ou N :
/// un appui bref ne suffit pas, pour ne rien valider par mégarde en tapant.
@MainActor
@Observable
public final class ZeboInitiatives {
    public enum Choice: Sendable {
        case accept
        case refuse
    }

    public struct Proposal: Identifiable, Equatable, Sendable {
        public let id = UUID()
        public let text: String
    }

    /// La proposition affichée.
    public private(set) var current: Proposal?
    /// La touche maintenue, en attendant que l'appui soit assez long.
    public private(set) var held: Choice?
    /// Combien de temps maintenir Y ou N.
    public let holdDuration: Duration

    /// Prévient la fenêtre des propositions quand une arrive ou s'en va.
    @ObservationIgnored public var onChange: ((Proposal?) -> Void)?

    @ObservationIgnored private var queue: [(proposal: Proposal, answer: CheckedContinuation<Bool, Never>)] = []
    /// Change à chaque appui : relâcher puis rappuyer recommence le compte.
    @ObservationIgnored private var pressID = UUID()

    public init(holdDuration: Duration = .milliseconds(700)) {
        self.holdDuration = holdDuration
    }

    /// Propose une initiative et attend la réponse : `true` si elle est acceptée.
    public func ask(_ text: String) async -> Bool {
        await withCheckedContinuation { answer in
            queue.append((Proposal(text: text), answer))
            if current == nil { showNext() }
        }
    }

    /// Y ou N enfoncée : la décision tombe si on la maintient assez longtemps.
    public func press(_ choice: Choice) {
        guard current != nil, held == nil else { return }
        held = choice
        let pressID = UUID()
        self.pressID = pressID
        Task {
            try? await Task.sleep(for: holdDuration)
            guard self.pressID == pressID, held == choice else { return }
            choose(choice)
        }
    }

    /// Relâchée trop tôt : rien n'est décidé.
    public func release(_ choice: Choice) {
        guard held == choice else { return }
        held = nil
        pressID = UUID()
    }

    /// Accepte ou refuse la proposition affichée (un clic décide tout de suite).
    public func choose(_ choice: Choice) {
        guard current != nil, !queue.isEmpty else { return }
        let answer = queue.removeFirst().answer
        held = nil
        pressID = UUID()
        answer.resume(returning: choice == .accept)
        showNext()
    }

    /// Retire toutes les propositions, refusées.
    public func dismissAll() {
        let answers = queue.map(\.answer)
        queue = []
        held = nil
        pressID = UUID()
        current = nil
        onChange?(nil)
        for answer in answers { answer.resume(returning: false) }
    }

    private func showNext() {
        current = queue.first?.proposal
        onChange?(current)
    }
}
