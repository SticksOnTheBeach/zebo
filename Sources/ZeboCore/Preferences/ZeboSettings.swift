import Foundation
import Observation

/// Retient les préférences de Zebo d'un lancement à l'autre.
@MainActor
public protocol PreferencesStore: AnyObject {
    func loadPreferences() -> ZeboPreferences?
    func savePreferences(_ preferences: ZeboPreferences)
}

/// Stockage dans les préférences de l'app, en JSON.
@MainActor
public final class UserDefaultsPreferencesStore: PreferencesStore {
    private static let key = "preferences"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadPreferences() -> ZeboPreferences? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(ZeboPreferences.self, from: data)
    }

    public func savePreferences(_ preferences: ZeboPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

/// Les préférences en cours, partagées par l'app et ses vues ; chaque changement est enregistré.
@MainActor
@Observable
public final class ZeboSettings {
    public var preferences: ZeboPreferences {
        didSet { store.savePreferences(preferences) }
    }

    @ObservationIgnored private let store: any PreferencesStore

    public init(store: any PreferencesStore) {
        self.store = store
        preferences = store.loadPreferences() ?? .standard
    }
}
