import Foundation
import Testing

@testable import ZeboCore

@MainActor
@Suite("Préférences de Zebo")
struct ZeboSettingsTests {
    private final class MemoryStore: PreferencesStore {
        var saved: ZeboPreferences?

        func loadPreferences() -> ZeboPreferences? { saved }
        func savePreferences(_ preferences: ZeboPreferences) { saved = preferences }
    }

    @Test("Sans préférences enregistrées, on part des réglages par défaut")
    func startsWithStandardPreferences() {
        let settings = ZeboSettings(store: MemoryStore())
        #expect(settings.preferences == .standard)
    }

    @Test("Chaque changement est enregistré")
    func changesAreSaved() {
        let store = MemoryStore()
        let settings = ZeboSettings(store: store)
        settings.preferences.name = "Mael"
        #expect(store.saved?.name == "Mael")
    }

    @Test("Les préférences enregistrées sont relues au lancement")
    func savedPreferencesAreLoaded() {
        let store = MemoryStore()
        store.saved = ZeboPreferences(name: "Mael", personality: .zen, showsClock: false, sleepsWhenClosed: false)
        #expect(ZeboSettings(store: store).preferences == store.saved)
    }

    @Test("Les préférences survivent à un redémarrage, dans les préférences de l'app")
    func userDefaultsStoreRoundTrips() throws {
        let suite = "zebo.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = ZeboPreferences(
            name: "Mael", personality: .playful, showsClock: false, sleepsWhenClosed: true)
        UserDefaultsPreferencesStore(defaults: defaults).savePreferences(preferences)
        #expect(UserDefaultsPreferencesStore(defaults: defaults).loadPreferences() == preferences)
    }
}

@Suite("Préférences enregistrées avant le choix de l'éditeur")
struct LegacyPreferencesTests {
    @Test("Des préférences sans éditeur se relisent quand même")
    func decodesPreferencesWithoutIDE() throws {
        let json = #"{"name":"Mael","personality":"zen","showsClock":true,"sleepsWhenClosed":false}"#
        let preferences = try JSONDecoder().decode(ZeboPreferences.self, from: Data(json.utf8))
        #expect(preferences.name == "Mael")
        #expect(preferences.ide == nil)
    }
}
