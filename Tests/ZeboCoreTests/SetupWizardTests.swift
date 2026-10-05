import Foundation
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
        #expect(wizard.step == .ide)
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
        let draft = ZeboPreferences(name: "Mael", showsClock: false, sleepsWhenClosed: true)
        #expect(SetupWizard(draft: draft).preferences == draft)
    }
}

@MainActor
@Suite("Choix de l'éditeur de code")
struct IDEChoiceTests {
    /// Ne connaît que les éditeurs qu'on lui donne.
    private struct FakeLocator: ApplicationLocator {
        var installed: [String: URL]
        func locate(_ ide: IDE) -> URL? { installed[ide.id] }
    }

    private let vscode = IDE.catalog[0]
    private let vscodeURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")

    @Test("Choisir un éditeur installé enregistre son emplacement")
    func choosingAnInstalledIDE() {
        let wizard = SetupWizard(locator: FakeLocator(installed: ["vscode": vscodeURL]))
        wizard.chooseIDE(vscode)
        let choice = IDEChoice(id: "vscode", name: "VS Code", path: vscodeURL.path)
        #expect(wizard.ideSearch == .found(choice))
        #expect(wizard.preferences.ide == choice)
    }

    @Test("Un éditeur introuvable n'est pas enregistré")
    func choosingAMissingIDE() {
        let wizard = SetupWizard(locator: FakeLocator(installed: [:]))
        wizard.chooseIDE(vscode)
        #expect(wizard.ideSearch == .notFound(vscode))
        #expect(wizard.preferences.ide == nil)
    }

    @Test("On peut indiquer soi-même où est l'éditeur introuvable")
    func choosingTheMissingIDEByHand() {
        let wizard = SetupWizard(locator: FakeLocator(installed: [:]))
        wizard.chooseIDE(vscode)
        let url = URL(fileURLWithPath: "/Users/me/Apps/Code.app")
        wizard.chooseApplication(at: url, as: vscode)
        #expect(wizard.preferences.ide == IDEChoice(id: "vscode", name: "VS Code", path: url.path))
    }

    @Test("Une autre app prend le nom de son fichier")
    func choosingAnotherApplication() {
        let wizard = SetupWizard()
        wizard.chooseApplication(at: URL(fileURLWithPath: "/Applications/Nova.app"), as: nil)
        #expect(
            wizard.preferences.ide == IDEChoice(id: IDEChoice.customID, name: "Nova", path: "/Applications/Nova.app"))
    }

    @Test("Un éditeur déjà choisi est retrouvé à la reconfiguration")
    func previousChoiceIsKept() {
        let choice = IDEChoice(id: "xcode", name: "Xcode", path: "/Applications/Xcode.app")
        var draft = ZeboPreferences.standard
        draft.ide = choice
        #expect(SetupWizard(draft: draft).ideSearch == .found(choice))
    }

    @Test("Le catalogue n'a pas deux éditeurs avec le même identifiant")
    func catalogIDsAreUnique() {
        #expect(Set(IDE.catalog.map(\.id)).count == IDE.catalog.count)
    }
}
