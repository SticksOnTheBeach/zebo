import Observation

/// Une fenêtre qui naît de la notch et y retourne : la notch se détache et devient une fenêtre,
/// on s'y affaire, puis Zebo regagne la notch. Sert à la configuration et aux nouveaux projets.
@MainActor
@Observable
public final class DetachedWindowFlow {
    public enum Phase: Equatable, Sendable {
        /// Rien en cours : la notch vit sa vie.
        case idle
        /// La notch se détache et rejoint le centre de l'écran.
        case detaching
        /// La fenêtre est ouverte.
        case presenting
        /// C'est fini : Zebo retourne dans la notch.
        case returning
    }

    public private(set) var phase: Phase = .idle

    /// Prévient le contrôleur pour afficher/masquer l'animation et la fenêtre.
    @ObservationIgnored public var onPhaseChange: ((Phase) -> Void)?

    public init() {}

    /// Pendant que la fenêtre existe, la notch reste fermée.
    public var isIdle: Bool { phase == .idle }

    /// La notch se détache.
    public func open() {
        guard phase == .idle else { return }
        setPhase(.detaching)
    }

    /// L'animation est finie : la fenêtre prend le relais.
    public func finishDetaching() {
        guard phase == .detaching else { return }
        setPhase(.presenting)
    }

    /// La fenêtre a été fermée avant la fin : la notch revient tout de suite.
    public func close() {
        guard phase != .idle else { return }
        setPhase(.idle)
    }

    /// C'est fini : Zebo retourne dans la notch.
    public func finish() {
        guard phase == .presenting else { return }
        setPhase(.returning)
    }

    /// Zebo est rentré dans la notch : elle reprend sa place.
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
