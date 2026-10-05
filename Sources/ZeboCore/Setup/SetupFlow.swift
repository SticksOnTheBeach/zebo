import Observation

/// Le parcours de configuration de Zebo : la notch se détache pour devenir une fenêtre,
/// la configuration se fait dans cette fenêtre, puis la fenêtre retourne dans la notch.
@MainActor
@Observable
public final class SetupFlow {
    public enum Phase: Equatable, Sendable {
        /// Rien en cours : la notch vit sa vie.
        case idle
        /// La notch se détache et rejoint le centre de l'écran.
        case detaching
        /// La fenêtre de configuration est ouverte.
        case configuring
        /// Configuration terminée : la fenêtre se rétracte dans la notch.
        case returning
    }

    public private(set) var phase: Phase = .idle
    public private(set) var isComplete: Bool

    /// Prévient le contrôleur pour afficher/masquer l'animation et la fenêtre.
    @ObservationIgnored public var onPhaseChange: ((Phase) -> Void)?

    @ObservationIgnored private let store: any SetupStore

    public init(store: any SetupStore) {
        self.store = store
        isComplete = store.isSetupComplete
    }

    /// Zebo n'est pas encore configuré : la notch propose de le faire.
    public var needsSetup: Bool { !isComplete }

    /// Pendant la configuration, la notch reste fermée.
    public var isNotchAvailable: Bool { phase == .idle }

    /// Le bouton « Configurer » a été cliqué : la notch se détache.
    public func start() {
        guard needsSetup else { return }
        reconfigure()
    }

    /// Refaire la configuration, même si elle a déjà été faite.
    public func reconfigure() {
        guard phase == .idle else { return }
        setPhase(.detaching)
    }

    /// L'animation est finie : la fenêtre de configuration prend le relais.
    public func finishDetaching() {
        guard phase == .detaching else { return }
        setPhase(.configuring)
    }

    /// La fenêtre a été fermée avant la fin : on pourra recommencer plus tard.
    public func close() {
        guard phase != .idle else { return }
        setPhase(.idle)
    }

    /// Configuration terminée : elle ne sera plus proposée, et la fenêtre retourne dans la notch.
    public func complete() {
        guard phase == .configuring else { return }
        store.isSetupComplete = true
        isComplete = true
        setPhase(.returning)
    }

    /// La fenêtre est rentrée dans la notch : elle reprend sa place.
    public func finishReturning() {
        guard phase == .returning else { return }
        setPhase(.idle)
    }

    private func setPhase(_ newPhase: Phase) {
        guard newPhase != phase else { return }
        phase = newPhase
        onPhaseChange?(newPhase)
    }
}
