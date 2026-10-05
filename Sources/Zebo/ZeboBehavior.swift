import Observation
import SwiftUI
import ZeboCore

/// Ce que fait Zebo quand on clique dessus : il parle… et si on insiste trop,
/// il tombe dans les pommes, est éjecté de la notch et tombe en bas de l'écran.
@MainActor
@Observable
final class ZeboBehavior {
    enum State {
        /// Dans la notch, tout va bien.
        case normal
        /// Sonné : yeux en spirale, étoiles autour de la tête.
        case dizzy
        /// En pleine chute à travers l'écran.
        case flying
        /// Sorti de l'écran, il va revenir.
        case gone
    }

    private(set) var state: State = .normal
    /// Trajectoire de la chute en cours.
    private(set) var flight: Flight?

    /// Prévient le contrôleur pour afficher/masquer la fenêtre de chute.
    @ObservationIgnored var onFlightChange: ((Bool) -> Void)?

    /// Zebo est dans la notch (même sonné).
    var isHome: Bool { state == .normal || state == .dizzy }

    @ObservationIgnored private var recentClicks: [Date] = []
    /// Moment où un clic a fait parler Zebo pour la dernière fois (pour le cooldown).
    @ObservationIgnored private var lastMessageDate: Date?
    @ObservationIgnored private let model: NotchModel
    @ObservationIgnored private let speech: ZeboSpeech

    /// Clics d'affilée qui le font tomber dans les pommes…
    private static let clicksToFaint = 3
    /// …s'ils tiennent tous dans cette durée.
    private static let clickWindow: TimeInterval = 1.5
    /// Après un message, un clic ne peut en lancer un nouveau qu'au bout de ce délai.
    private static let messageCooldown: TimeInterval = 4

    init(model: NotchModel, speech: ZeboSpeech) {
        self.model = model
        self.speech = speech
    }

    func poke() {
        guard state == .normal else { return }

        let now = Date()
        recentClicks = recentClicks.filter { now.timeIntervalSince($0) < Self.clickWindow } + [now]

        // Les clics comptent toujours pour l'évanouissement, même pendant le cooldown.
        if recentClicks.count >= Self.clicksToFaint {
            faint()
            return
        }

        // Cooldown : pas de nouveau message tant que le précédent est trop récent.
        if let last = lastMessageDate, now.timeIntervalSince(last) < Self.messageCooldown {
            return
        }
        lastMessageDate = now
        speech.sayRandom()
    }

    private func faint() {
        recentClicks = []
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

        let screen = model.screenFrame
        let center = model.zeboScreenCenter
        // Coordonnées de la fenêtre de chute (plein écran, origine en haut à gauche).
        let origin = CGPoint(x: center.x - screen.minX, y: screen.maxY - center.y)
        let direction: CGFloat = Bool.random() ? 1 : -1

        let newFlight = Flight(
            start: Date(),
            origin: origin,
            // Catapulté vers le haut et sur le côté.
            velocity: CGVector(dx: direction * .random(in: 180...320), dy: -640),
            size: model.zeboFrame.width,
            spinSpeed: Double(direction) * .random(in: 380...620),
            floorY: screen.height
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
            state = .normal
        }
        speech.say("Me revoilà ! 😤")
        // « Me revoilà » compte comme un message : pas de spam juste après son retour.
        lastMessageDate = Date()
    }
}
