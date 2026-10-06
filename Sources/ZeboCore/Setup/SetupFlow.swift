import Observation

/// Le parcours de configuration de Zebo : la notch se détache pour devenir une fenêtre,
/// la configuration se fait dans cette fenêtre, puis Zebo retourne dans la notch.
@MainActor
@Observable
public final class SetupFlow {
    public typealias Phase = DetachedWindowFlow.Phase

    /// La fenêtre de configuration, qui naît de la notch et y retourne.
    public let window = DetachedWindowFlow()
    public private(set) var isComplete: Bool

    @ObservationIgnored private let store: any SetupStore

    public init(store: any SetupStore) {
        self.store = store
        isComplete = store.isSetupComplete
    }

    public var phase: Phase { window.phase }

    /// Prévient le contrôleur pour afficher/masquer l'animation et la fenêtre.
    public var onPhaseChange: ((Phase) -> Void)? {
        get { window.onPhaseChange }
        set { window.onPhaseChange = newValue }
    }

    /// Zebo n'est pas encore configuré : la notch propose de le faire.
    public var needsSetup: Bool { !isComplete }

    /// Pendant la configuration, la notch reste fermée.
    public var isNotchAvailable: Bool { window.isIdle }

    /// Le bouton « Configurer » a été cliqué : la notch se détache.
    public func start() {
        guard needsSetup else { return }
        reconfigure()
    }

    /// Refaire la configuration, même si elle a déjà été faite.
    public func reconfigure() {
        window.open()
    }

    /// L'animation est finie : la fenêtre de configuration prend le relais.
    public func finishDetaching() {
        window.finishDetaching()
    }

    /// La fenêtre a été fermée avant la fin : on pourra recommencer plus tard.
    public func close() {
        window.close()
    }

    /// Configuration terminée : elle ne sera plus proposée, et Zebo retourne dans la notch.
    public func complete() {
        guard phase == .presenting else { return }
        store.isSetupComplete = true
        isComplete = true
        window.finish()
    }

    /// Zebo est rentré dans la notch : elle reprend sa place.
    public func finishReturning() {
        window.finishReturning()
    }
}
