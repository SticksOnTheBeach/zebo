import Foundation
import Observation

/// Les étapes de la configuration et les réglages en cours de saisie.
/// Rien n'est appliqué avant la fin : `preferences` donne le résultat à enregistrer.
@MainActor
@Observable
public final class SetupWizard {
    public enum Step: Int, CaseIterable, Comparable, Sendable {
        case welcome
        case name
        case personality
        case notch
        case ready

        public static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Longueur maximale du prénom.
    public static let maxNameLength = 24

    public private(set) var step: Step = .welcome
    /// Dernier déplacement : vers l'étape suivante (`true`) ou la précédente.
    public private(set) var isMovingForward = true
    /// Réglages en cours de saisie.
    public var draft: ZeboPreferences

    public init(draft: ZeboPreferences = .standard) {
        self.draft = draft
    }

    /// Prénom sans espaces autour.
    public var trimmedName: String {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var canGoBack: Bool { step != .welcome }
    public var isLastStep: Bool { step == .ready }

    /// On ne quitte l'étape du prénom qu'avec un prénom.
    public var canAdvance: Bool {
        switch step {
        case .name: !trimmedName.isEmpty
        default: !isLastStep
        }
    }

    public func advance() {
        guard canAdvance, let next = Step(rawValue: step.rawValue + 1) else { return }
        isMovingForward = true
        step = next
    }

    public func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        isMovingForward = false
        step = previous
    }

    /// Les réglages à enregistrer, prénom nettoyé.
    public var preferences: ZeboPreferences {
        var preferences = draft
        preferences.name = String(trimmedName.prefix(Self.maxNameLength))
        return preferences
    }
}
