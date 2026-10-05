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
        store.saved = ZeboPreferences(name: "Mael", showsClock: false, sleepsWhenClosed: false)
        #expect(ZeboSettings(store: store).preferences == store.saved)
    }

    @Test("Les préférences survivent à un redémarrage, dans les préférences de l'app")
    func userDefaultsStoreRoundTrips() throws {
        let suite = "zebo.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = ZeboPreferences(
            name: "Mael", showsClock: false, sleepsWhenClosed: true)
        UserDefaultsPreferencesStore(defaults: defaults).savePreferences(preferences)
        #expect(UserDefaultsPreferencesStore(defaults: defaults).loadPreferences() == preferences)
    }
}

@Suite("Préférences enregistrées par une ancienne version")
struct LegacyPreferencesTests {
    private func decode(_ json: String) throws -> ZeboPreferences {
        try JSONDecoder().decode(ZeboPreferences.self, from: Data(json.utf8))
    }

    @Test("Des préférences sans éditeur se relisent quand même")
    func decodesPreferencesWithoutIDE() throws {
        let preferences = try decode(#"{"name":"Mael","personality":"zen","showsClock":true,"sleepsWhenClosed":false}"#)
        #expect(preferences.name == "Mael")
        #expect(preferences.ides.isEmpty)
        #expect(!preferences.sleepsWhenClosed)
    }

    @Test("Un éditeur unique devient le premier de la liste")
    func migratesSingleIDE() throws {
        let preferences = try decode(
            #"{"name":"Mael","showsClock":true,"sleepsWhenClosed":true,"ide":{"id":"xcode","name":"Xcode","path":"/Applications/Xcode.app"}}"#
        )
        #expect(preferences.ides == [IDEChoice(id: "xcode", name: "Xcode", path: "/Applications/Xcode.app")])
    }

    @Test("Des préférences vides prennent les valeurs par défaut")
    func emptyPreferencesUseDefaults() throws {
        #expect(try decode("{}") == .standard)
    }

    @Test("Le langage préféré est enregistré, et un langage inconnu est oublié")
    func favoriteLanguageRoundTrips() throws {
        var preferences = ZeboPreferences.standard
        preferences.favoriteLanguage = .rust
        let data = try JSONEncoder().encode(preferences)
        #expect(try JSONDecoder().decode(ZeboPreferences.self, from: data).favoriteLanguage == .rust)
        #expect(try decode(#"{"favoriteLanguage":"cobol"}"#).favoriteLanguage == nil)
    }
}
