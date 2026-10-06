import Testing

@testable import ZeboCore

@MainActor
@Suite("Fenêtre détachée de la notch")
struct DetachedWindowFlowTests {
    @Test("La notch se détache, la fenêtre s'ouvre, puis Zebo retourne dans la notch")
    func fullCycle() {
        let flow = DetachedWindowFlow()
        var phases: [DetachedWindowFlow.Phase] = []
        flow.onPhaseChange = { phases.append($0) }
        flow.open()
        flow.finishDetaching()
        flow.finish()
        flow.finishReturning()
        #expect(phases == [.detaching, .presenting, .returning, .idle])
        #expect(flow.isIdle)
    }

    @Test("Une seule fenêtre à la fois : rouvrir pendant qu'elle existe ne fait rien")
    func openIsIgnoredWhileBusy() {
        let flow = DetachedWindowFlow()
        flow.open()
        flow.finishDetaching()
        flow.open()
        #expect(flow.phase == .presenting)
    }

    @Test("Fermer la fenêtre rend la notch tout de suite, sans retour animé")
    func closeGoesStraightToIdle() {
        let flow = DetachedWindowFlow()
        flow.open()
        flow.finishDetaching()
        flow.close()
        #expect(flow.phase == .idle)
    }

    @Test("On ne finit que depuis la fenêtre ouverte")
    func finishRequiresPresenting() {
        let flow = DetachedWindowFlow()
        flow.finish()
        #expect(flow.phase == .idle)
    }
}
