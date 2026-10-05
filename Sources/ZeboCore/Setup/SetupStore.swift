import Foundation

/// Retient si Zebo a déjà été configuré, d'un lancement à l'autre.
@MainActor
public protocol SetupStore: AnyObject {
    var isSetupComplete: Bool { get set }
}

/// Stockage dans les préférences de l'app.
@MainActor
public final class UserDefaultsSetupStore: SetupStore {
    private static let key = "isSetupComplete"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var isSetupComplete: Bool {
        get { defaults.bool(forKey: Self.key) }
        set { defaults.set(newValue, forKey: Self.key) }
    }
}
