import Testing

@testable import ZeboCore

@MainActor
@Suite("Assistant de configuration")
struct SetupWizardTests {
    private let wizard = SetupWizard()

    @Test("Commence par l'accueil, sans retour possible")
    func startsWithWelcome() {
        #expect(wizard.step == .welcome)
        #expect(!wizard.canGoBack)
        #expect(wizard.canAdvance)
    }

    @Test("Bloque à l'étape du prénom tant qu'il est vide")
    func nameIsRequired() {
        wizard.advance()
        #expect(wizard.step == .name)
        wizard.draft.name = "   "
        #expect(!wizard.canAdvance)
        wizard.advance()
        #expect(wizard.step == .name)

        wizard.draft.name = "Mael"
        wizard.advance()
        #expect(wizard.step == .personality)
    }

    @Test("Revenir en arrière change le sens du déplacement")
    func goingBackReversesDirection() {
        wizard.advance()
        #expect(wizard.isMovingForward)
        wizard.goBack()
        #expect(wizard.step == .welcome)
        #expect(!wizard.isMovingForward)
    }

    @Test("La dernière étape ne mène nulle part")
    func lastStepIsTheEnd() {
        wizard.draft.name = "Mael"
        for _ in SetupWizard.Step.allCases { wizard.advance() }
        #expect(wizard.step == .ready)
        #expect(wizard.isLastStep)
        #expect(!wizard.canAdvance)
    }

    @Test("Le prénom enregistré est nettoyé et raccourci")
    func preferencesCleanTheName() {
        wizard.draft.name = "  Mael  "
        #expect(wizard.preferences.name == "Mael")
        wizard.draft.name = String(repeating: "a", count: 40)
        #expect(wizard.preferences.name.count == SetupWizard.maxNameLength)
    }

    @Test("Part des réglages qu'on lui donne")
    func startsFromGivenDraft() {
        let draft = ZeboPreferences(name: "Mael", personality: .zen, showsClock: false, sleepsWhenClosed: true)
        #expect(SetupWizard(draft: draft).preferences == draft)
    }
}
