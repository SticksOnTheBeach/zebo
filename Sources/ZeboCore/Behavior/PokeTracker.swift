import Foundation

/// Décide ce que provoque un clic sur Zebo : un nouveau message, rien (cooldown),
/// ou l'évanouissement quand on clique trop vite.
public struct PokeTracker: Sendable {
    public enum Outcome: Equatable, Sendable {
        /// Zebo dit quelque chose.
        case speak
        /// Trop tôt après le dernier message : on ne fait rien.
        case ignore
        /// Trop de clics d'affilée : il tombe dans les pommes.
        case faint
    }

    public struct Rules: Sendable {
        /// Clics d'affilée qui le font tomber dans les pommes…
        public var clicksToFaint: Int
        /// …s'ils tiennent tous dans cette durée.
        public var clickWindow: TimeInterval
        /// Après un message, un clic ne peut en lancer un nouveau qu'au bout de ce délai.
        public var messageCooldown: TimeInterval

        public static let standard = Rules(clicksToFaint: 3, clickWindow: 1.5, messageCooldown: 4)

        public init(clicksToFaint: Int, clickWindow: TimeInterval, messageCooldown: TimeInterval) {
            self.clicksToFaint = clicksToFaint
            self.clickWindow = clickWindow
            self.messageCooldown = messageCooldown
        }
    }

    private let rules: Rules
    private var recentClicks: [Date] = []
    /// Moment du dernier message (pour le cooldown).
    private var lastMessageDate: Date?

    public init(rules: Rules = .standard) {
        self.rules = rules
    }

    public mutating func registerPoke(at now: Date) -> Outcome {
        recentClicks = recentClicks.filter { now.timeIntervalSince($0) < rules.clickWindow } + [now]

        // Les clics comptent toujours pour l'évanouissement, même pendant le cooldown.
        if recentClicks.count >= rules.clicksToFaint {
            recentClicks = []
            return .faint
        }

        if let last = lastMessageDate, now.timeIntervalSince(last) < rules.messageCooldown {
            return .ignore
        }
        lastMessageDate = now
        return .speak
    }

    /// Un message lancé autrement que par un clic compte aussi pour le cooldown.
    public mutating func noteMessage(at date: Date) {
        lastMessageDate = date
    }
}
