import Foundation
import Testing

@testable import ZeboCore

@MainActor
@Suite("Parcours de configuration")
struct SetupFlowTests {
    private final class MemoryStore: SetupStore {
        var isSetupComplete: Bool

        init(isSetupComplete: Bool = false) {
            self.isSetupComplete = isSetupComplete
        }
    }

    private let store = MemoryStore()
    private let flow: SetupFlow

    init() {
        flow = SetupFlow(store: store)
    }

    @Test("Au premier lancement, Zebo demande à être configuré")
    func needsSetupAtFirstLaunch() {
        #expect(flow.needsSetup)
        #expect(flow.phase == .idle)
        #expect(flow.isNotchAvailable)
    }

    @Test("Déjà configuré, il ne le redemande pas")
    func remembersCompletedSetup() {
        let flow = SetupFlow(store: MemoryStore(isSetupComplete: true))
        #expect(!flow.needsSetup)
        flow.start()
        #expect(flow.phase == .idle)
    }

    @Test("Le bouton détache la notch, puis la fenêtre de configuration s'ouvre")
    func startThenFinishDetaching() {
        var phases: [SetupFlow.Phase] = []
        flow.onPhaseChange = { phases.append($0) }

        flow.start()
        #expect(flow.phase == .detaching)
        #expect(!flow.isNotchAvailable)

        flow.finishDetaching()
        #expect(flow.phase == .presenting)
        #expect(phases == [.detaching, .presenting])
    }

    @Test("Un deuxième clic pendant l'animation ne relance rien")
    func startIsIgnoredWhileDetaching() {
        var changes = 0
        flow.onPhaseChange = { _ in changes += 1 }
        flow.start()
        flow.start()
        #expect(changes == 1)
    }

    @Test("La fenêtre ne s'ouvre qu'après le détachement")
    func finishDetachingRequiresDetaching() {
        flow.finishDetaching()
        #expect(flow.phase == .idle)
    }

    @Test("Fermer la fenêtre rend la notch, sans valider la configuration")
    func closingKeepsSetupPending() {
        flow.start()
        flow.finishDetaching()
        flow.close()
        #expect(flow.phase == .idle)
        #expect(flow.needsSetup)
        #expect(!store.isSetupComplete)
    }

    @Test("Terminer la configuration la mémorise, puis la fenêtre retourne dans la notch")
    func completingIsRememberedThenReturns() {
        flow.start()
        flow.finishDetaching()
        flow.complete()
        #expect(flow.phase == .returning)
        #expect(!flow.isNotchAvailable)
        #expect(!flow.needsSetup)
        #expect(store.isSetupComplete)

        flow.finishReturning()
        #expect(flow.phase == .idle)
        #expect(flow.isNotchAvailable)
    }

    @Test("On ne termine que depuis la fenêtre de configuration")
    func completeRequiresConfiguring() {
        flow.complete()
        #expect(flow.phase == .idle)
        #expect(!store.isSetupComplete)
    }

    @Test("Déjà configuré, on peut quand même tout refaire")
    func reconfigureAfterCompletion() {
        let flow = SetupFlow(store: MemoryStore(isSetupComplete: true))
        flow.reconfigure()
        #expect(flow.phase == .detaching)
    }

    @Test("Les préférences retiennent la configuration d'un lancement à l'autre")
    func userDefaultsStorePersists() throws {
        let suite = "zebo.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        UserDefaultsSetupStore(defaults: defaults).isSetupComplete = true
        #expect(UserDefaultsSetupStore(defaults: defaults).isSetupComplete)
    }
}
