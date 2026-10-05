import CoreGraphics
import Foundation
import Observation

/// Ce que fait Zebo quand on clique dessus : il parle… et si on insiste trop,
/// il tombe dans les pommes, est éjecté de la notch et tombe en bas de l'écran.
@MainActor
@Observable
public final class ZeboBehavior {
    public enum State: Sendable {
        /// Dans la notch, tout va bien.
        case normal
        /// Sonné : yeux en spirale, étoiles autour de la tête.
        case dizzy
        /// En pleine chute à travers l'écran.
        case flying
        /// Sorti de l'écran, il va revenir.
        case gone
    }

    public private(set) var state: State = .normal
    /// Trajectoire de la chute en cours.
    public private(set) var flight: Flight?

    /// Prévient le contrôleur pour afficher/masquer la fenêtre de chute.
    @ObservationIgnored public var onFlightChange: ((Bool) -> Void)?

    /// Zebo est dans la notch (même sonné).
    public var isHome: Bool { state == .normal || state == .dizzy }

    @ObservationIgnored private var pokes = PokeTracker()
    @ObservationIgnored private let placement: any ZeboPlacement
    @ObservationIgnored private let speech: any ZeboSpeaking

    public init(placement: any ZeboPlacement, speech: any ZeboSpeaking) {
        self.placement = placement
        self.speech = speech
    }

    public func poke() {
        guard state == .normal else { return }

        switch pokes.registerPoke(at: Date()) {
        case .speak: speech.sayRandom()
        case .ignore: break
        case .faint: faint()
        }
    }

    private func faint() {
        state = .dizzy
        speech.say("Ouuuh… je vois des étoiles…")

        Task {
            // Il gigote de gauche à droite…
            try? await Task.sleep(for: .seconds(1.3))
            let duration = launch()
            // …vole à travers l'écran…
            try? await Task.sleep(for: .seconds(duration))
            land()
            // …et revient tout seul un peu plus tard.
            try? await Task.sleep(for: .seconds(3))
            comeBack()
        }
    }

    /// Éjecte Zebo de la notch. Renvoie la durée de la chute.
    private func launch() -> Double {
        speech.silence()

        var generator = SystemRandomNumberGenerator()
        let newFlight = Flight.ejection(
            from: placement.zeboScreenCenter,
            in: placement.screenFrame,
            size: placement.zeboFrame.width,
            using: &generator
        )
        flight = newFlight
        state = .flying
        onFlightChange?(true)
        return newFlight.duration
    }

    private func land() {
        state = .gone
        flight = nil
        onFlightChange?(false)
    }

    private func comeBack() {
        state = .normal
        speech.say("Me revoilà ! 😤")
        // « Me revoilà » compte comme un message : pas de spam juste après son retour.
        pokes.noteMessage(at: Date())
    }
}
