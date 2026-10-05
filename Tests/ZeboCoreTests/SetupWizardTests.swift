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
@Suite("Choix des éditeurs de code")
struct IDEChoiceTests {
    /// Ne connaît que les éditeurs qu'on lui donne.
    private struct FakeLocator: ApplicationLocator {
        var installed: [String: URL]
        func locate(_ ide: IDE) -> URL? { installed[ide.id] }
    }

    private let vscode = IDE.catalog.first { $0.id == "vscode" }!
    private let xcode = IDE.catalog.first { $0.id == "xcode" }!
    private let vscodeURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
    private let xcodeURL = URL(fileURLWithPath: "/Applications/Xcode.app")

    private func makeWizard(installed: [String: URL] = [:]) -> SetupWizard {
        SetupWizard(locator: FakeLocator(installed: installed))
    }

    @Test("Choisir un éditeur installé enregistre son emplacement")
    func choosingAnInstalledIDE() {
        let wizard = makeWizard(installed: ["vscode": vscodeURL])
        wizard.toggleIDE(vscode)
        let choice = IDEChoice(id: "vscode", name: "VS Code", path: vscodeURL.path)
        #expect(wizard.ideSearch == .found(choice))
        #expect(wizard.preferences.ides == [choice])
        #expect(wizard.isSelected(vscode))
    }

    @Test("On peut en choisir plusieurs")
    func choosingSeveralIDEs() {
        let wizard = makeWizard(installed: ["vscode": vscodeURL, "xcode": xcodeURL])
        wizard.toggleIDE(vscode)
        wizard.toggleIDE(xcode)
        #expect(wizard.preferences.ides.map(\.id) == ["vscode", "xcode"])
    }

    @Test("Recliquer sur un éditeur choisi le retire")
    func togglingRemoves() {
        let wizard = makeWizard(installed: ["vscode": vscodeURL, "xcode": xcodeURL])
        wizard.toggleIDE(vscode)
        wizard.toggleIDE(xcode)
        wizard.toggleIDE(vscode)
        #expect(wizard.preferences.ides.map(\.id) == ["xcode"])
        #expect(!wizard.isSelected(vscode))
    }

    @Test("Un éditeur introuvable n'est pas ajouté")
    func choosingAMissingIDE() {
        let wizard = makeWizard()
        wizard.toggleIDE(vscode)
        #expect(wizard.ideSearch == .notFound(vscode))
        #expect(wizard.preferences.ides.isEmpty)
    }

    @Test("On peut indiquer soi-même où est l'éditeur introuvable")
    func choosingTheMissingIDEByHand() {
        let wizard = makeWizard()
        wizard.toggleIDE(vscode)
        let url = URL(fileURLWithPath: "/Users/me/Apps/Code.app")
        wizard.chooseApplication(at: url, as: vscode)
        #expect(wizard.preferences.ides == [IDEChoice(id: "vscode", name: "VS Code", path: url.path)])
    }

    @Test("Une autre app prend le nom de son fichier, sans doublon")
    func choosingAnotherApplication() {
        let wizard = makeWizard()
        let nova = URL(fileURLWithPath: "/Applications/Nova.app")
        wizard.chooseApplication(at: nova, as: nil)
        wizard.chooseApplication(at: nova, as: nil)
        #expect(wizard.preferences.ides == [IDEChoice(id: IDEChoice.customID, name: "Nova", path: nova.path)])
    }

    @Test("Les éditeurs déjà choisis sont retrouvés à la reconfiguration")
    func previousChoicesAreKept() {
        var draft = ZeboPreferences.standard
        draft.ides = [IDEChoice(id: "xcode", name: "Xcode", path: xcodeURL.path)]
        #expect(SetupWizard(draft: draft).isSelected(xcode))
    }

    @Test("Le catalogue n'a pas deux éditeurs avec le même identifiant")
    func catalogIDsAreUnique() {
        #expect(Set(IDE.catalog.map(\.id)).count == IDE.catalog.count)
    }
}
