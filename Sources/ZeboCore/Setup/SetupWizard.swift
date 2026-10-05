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
        case ide
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

    /// Résultat de la dernière recherche d'éditeur de code.
    public enum IDESearch: Equatable, Sendable {
        /// Rien de cherché pour l'instant.
        case none
        /// Trouvé (ou choisi à la main) et ajouté : voici où il est.
        case found(IDEChoice)
        /// Introuvable sur ce Mac.
        case notFound(IDE)
    }

    public private(set) var ideSearch: IDESearch = .none

    @ObservationIgnored private let locator: any ApplicationLocator

    public init(draft: ZeboPreferences = .standard, locator: any ApplicationLocator = NoApplicationLocator()) {
        self.draft = draft
        self.locator = locator
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

    // MARK: - Éditeurs de code

    /// Où se trouve l'éditeur, s'il est installé (sans le choisir).
    public func installedLocation(of ide: IDE) -> URL? {
        locator.locate(ide)
    }

    public func isSelected(_ ide: IDE) -> Bool {
        draft.ides.contains { $0.id == ide.id }
    }

    /// Ajouter un éditeur (Zebo cherche tout seul où il est installé), ou le retirer s'il était choisi.
    public func toggleIDE(_ ide: IDE) {
        if isSelected(ide) {
            draft.ides.removeAll { $0.id == ide.id }
            ideSearch = .none
            return
        }
        guard let url = locator.locate(ide) else {
            ideSearch = .notFound(ide)
            return
        }
        add(IDEChoice(id: ide.id, name: ide.name, path: url.path))
    }

    /// Une app choisie à la main : l'éditeur introuvable, ou un autre que ceux proposés.
    public func chooseApplication(at url: URL, as ide: IDE?) {
        let name = ide?.name ?? url.deletingPathExtension().lastPathComponent
        add(IDEChoice(id: ide?.id ?? IDEChoice.customID, name: name, path: url.path))
    }

    /// Ajoute l'éditeur, ou met à jour son emplacement s'il était déjà là.
    private func add(_ choice: IDEChoice) {
        draft.ides.removeAll { $0.path == choice.path || ($0.id == choice.id && choice.id != IDEChoice.customID) }
        draft.ides.append(choice)
        ideSearch = .found(choice)
    }

    /// Les réglages à enregistrer, prénom nettoyé.
    public var preferences: ZeboPreferences {
        var preferences = draft
        preferences.name = String(trimmedName.prefix(Self.maxNameLength))
        return preferences
    }
}
