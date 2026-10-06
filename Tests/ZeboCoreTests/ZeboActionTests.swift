import Foundation
import Testing

@testable import ZeboCore

private let vscode = IDEChoice(id: "vscode", name: "VS Code", path: "/Applications/Visual Studio Code.app")
private let rustRover = IDEChoice(id: "rustrover", name: "RustRover", path: "/Applications/RustRover.app")
private let game = ZeboProject(name: "Mon jeu", kind: .cpp, path: "/Dev/C++/Mon jeu", editor: rustRover)

private func request(
    _ type: String, editor: String = "", project: String = "", kind: String = "", name: String = ""
) -> ActionQuestion.Request {
    ActionQuestion.Request(type: type, editor: editor, project: project, kind: kind, name: name)
}

private func resolve(_ request: ActionQuestion.Request) throws(ZeboActionError) -> ZeboAction? {
    try ActionQuestion.resolve(request, editors: [vscode, rustRover], projects: [game])
}

@Suite("Actions de Zebo")
struct ActionQuestionTests {
    @Test("L'IA ne connaît que les éditeurs, les projets et les genres qu'on lui donne")
    func instructionsListWhatExists() {
        let text = ActionQuestion.instructions(editors: [vscode], projects: [game])
        #expect(text.contains("Ses éditeurs : VS Code."))
        #expect(text.contains("Mon jeu (C++)"))
        #expect(text.contains("rust (Rust)"))
    }

    @Test("La réponse JSON se lit : une phrase et une action")
    func parsesAnswer() {
        let json =
            #"{"reply":"J'ouvre Cursor !","action":{"type":"open_editor","editor":"Cursor","project":"","kind":"","name":""}}"#
        #expect(ActionQuestion.answer(fromJSON: json)?.action.editor == "Cursor")
        #expect(ActionQuestion.answer(fromJSON: "Coucou") == nil)
    }

    @Test("Un éditeur se retrouve sans tenir compte des majuscules, ni du nom complet")
    func findsEditors() throws {
        #expect(try resolve(request("open_editor", editor: "rustrover")) == .openEditor(rustRover))
        #expect(try resolve(request("open_editor", editor: "Visual Studio VS Code")) == .openEditor(vscode))
        #expect(throws: ZeboActionError.self) { try resolve(request("open_editor", editor: "Emacs")) }
    }

    @Test("Un projet s'ouvre avec l'éditeur demandé, le Finder, ou à défaut son éditeur habituel")
    func opensProjects() throws {
        #expect(
            try resolve(request("open_project", editor: "VS Code", project: "mon jeu"))
                == .openProject(game, with: .editor(vscode)))
        #expect(
            try resolve(request("open_project", editor: "Finder", project: "Mon jeu"))
                == .openProject(game, with: .finder))
        #expect(
            try resolve(request("open_project", project: "Mon jeu")) == .openProject(game, with: .editor(rustRover)))
        #expect(throws: ZeboActionError.self) { try resolve(request("open_project", project: "Inconnu")) }
    }

    @Test("Un projet se crée avec un genre connu ; le nom et l'éditeur ne sont que des propositions")
    func createsProjects() throws {
        #expect(
            try resolve(request("create_project", editor: "RustRover", kind: "rust", name: " Mon outil "))
                == .createProject(name: "Mon outil", kind: .rust, editor: rustRover))
        #expect(
            try resolve(request("create_project", kind: "Python", name: "Script"))
                == .createProject(name: "Script", kind: .python, editor: nil))
        #expect(
            try resolve(request("create_project", editor: "Emacs", kind: "rust"))
                == .createProject(name: "", kind: .rust, editor: nil))
        #expect(throws: ZeboActionError.self) { try resolve(request("create_project", kind: "cobol", name: "X")) }
    }

    @Test("Une initiative se lit avec la réponse ; les anciennes réponses, sans initiative, aussi")
    func parsesInitiative() {
        let json =
            #"{"reply":"Voilà !","action":{"type":"none","editor":"","project":"","kind":"","name":""},"initiative":{"text":"Je t'ouvre le Terminal ?","action":{"type":"open_project","editor":"Terminal","project":"Mon jeu","kind":"","name":""}}}"#
        #expect(ActionQuestion.answer(fromJSON: json)?.initiative?.text == "Je t'ouvre le Terminal ?")
        #expect(ActionQuestion.format.schema["required"] as? [String] == ["action", "initiative", "reply"])
    }

    @Test("« none » : Zebo répond sans rien faire")
    func noneDoesNothing() throws {
        #expect(try resolve(request("none")) == nil)
    }
}

/// Répond toujours la même chose.
private final class ScriptedAI: AIClient, @unchecked Sendable {
    let provider = AIProvider.claude
    let reply: String
    private(set) var prompts: [AIPrompt] = []

    init(reply: String) {
        self.reply = reply
    }

    func answer(_ prompt: AIPrompt) async throws -> String {
        prompts.append(prompt)
        return reply
    }
}

/// Retient ce qu'on lui demande de faire.
@MainActor
private final class RecordingPerformer: ZeboActionPerformer {
    let editors = [vscode, rustRover]
    private(set) var projects = [game]
    let failure: ZeboActionError?
    private(set) var performed: [ZeboAction] = []

    init(failure: ZeboActionError? = nil) {
        self.failure = failure
    }

    func perform(_ action: ZeboAction) async throws -> String {
        performed.append(action)
        if let failure { throw failure }
        if case .createProject(let name, let kind, let editor) = action {
            projects.append(ZeboProject(name: name, kind: kind, path: "/Dev/\(name)", editor: editor))
            return "« \(name) » est créé."
        }
        return "RustRover est ouvert."
    }
}

@MainActor
@Suite("Zebo agit depuis la discussion")
struct ZeboChatActionTests {
    private static let openRustRover =
        #"{"reply":"J'ouvre RustRover !","action":{"type":"open_editor","editor":"RustRover","project":"","kind":"","name":""}}"#

    private func chat(replying reply: String, performer: RecordingPerformer) -> (ZeboChat, ScriptedAI) {
        let ai = ScriptedAI(reply: reply)
        let chat = ZeboChat(initiatives: ZeboInitiatives(holdDuration: .milliseconds(50)))
        chat.client = ai
        chat.actions = performer
        return (chat, ai)
    }

    @Test("Zebo répond, fait l'action demandée et dit qu'elle est faite")
    func performsTheAction() async {
        let performer = RecordingPerformer()
        let (chat, ai) = chat(replying: Self.openRustRover, performer: performer)
        chat.draft = "Ouvre RustRover"
        chat.send()
        #expect(await waitUntil { chat.messages.last?.action == .done("RustRover est ouvert.") })
        #expect(chat.messages.last?.text == "J'ouvre RustRover !")
        #expect(performer.performed == [.openEditor(rustRover)])
        #expect(ai.prompts.first?.format != nil)
        #expect(ai.prompts.first?.instructions.contains("open_editor") == true)
        // L'IA se souviendra de ce qui a été fait.
        #expect(chat.conversation.last?.text.contains("Fait : RustRover est ouvert.") == true)
    }

    @Test("Une action ratée est expliquée sous la réponse")
    func explainsFailures() async {
        let performer = RecordingPerformer(failure: ZeboActionError("RustRover a disparu."))
        let (chat, _) = chat(replying: Self.openRustRover, performer: performer)
        chat.draft = "Ouvre RustRover"
        chat.send()
        #expect(await waitUntil { chat.messages.last?.action == .failed("RustRover a disparu.") })
    }

    @Test("Pour une question, Zebo répond sans rien faire")
    func asksBeforeActing() async {
        let performer = RecordingPerformer()
        let json =
            #"{"reply":"Dans VS Code ou RustRover ?","action":{"type":"none","editor":"","project":"","kind":"","name":""}}"#
        let (chat, _) = chat(replying: json, performer: performer)
        chat.draft = "Crée-moi un projet Rust"
        chat.send()
        #expect(await waitUntil { !chat.isWaiting })
        #expect(chat.messages.last?.text == "Dans VS Code ou RustRover ?")
        #expect(chat.messages.last?.action == nil)
        #expect(performer.performed.isEmpty)
    }

    @Test("Une réponse qui n'est pas du JSON s'affiche telle quelle")
    func plainTextStillShows() async {
        let (chat, _) = chat(replying: "Coucou !", performer: RecordingPerformer())
        chat.draft = "Salut"
        chat.send()
        #expect(await waitUntil { !chat.isWaiting })
        #expect(chat.messages.last?.text == "Coucou !")
    }

    private static let createRust =
        #"{"reply":"Je te prépare ça !","action":{"type":"create_project","editor":"RustRover","project":"","kind":"rust","name":"mon-outil"},"initiative":{"text":"Je t'ouvre aussi le Terminal dedans ?","action":{"type":"open_project","editor":"Terminal","project":"Mon outil","kind":"","name":""}}}"#

    @Test("Créer un projet ouvre la fiche, avec le nom et l'éditeur proposés par Zebo")
    func createGoesThroughTheDraft() async throws {
        let performer = RecordingPerformer()
        let (chat, _) = chat(replying: Self.createRust, performer: performer)
        chat.draft = "Crée-moi un projet Rust"
        chat.send()
        #expect(await waitUntil { chat.projectDraft != nil })
        let draft = try #require(chat.projectDraft)
        #expect(draft.name == "mon-outil")
        #expect(draft.editor == rustRover)
        #expect(chat.messages.last?.action == .waiting("Choisis son nom et son éditeur…"))
        #expect(performer.performed.isEmpty)

        // Un nom invalide ne part pas ; on le corrige, on change d'éditeur, et on crée.
        draft.name = "a/b"
        chat.confirmProjectDraft()
        #expect(chat.projectDraft != nil)
        draft.name = "Mon outil"
        draft.editor = vscode
        chat.confirmProjectDraft()
        #expect(chat.projectDraft == nil)
        #expect(await waitUntil { chat.messages.last?.action == .done("« Mon outil » est créé.") })
        #expect(performer.performed.first == .createProject(name: "Mon outil", kind: .rust, editor: vscode))
    }

    @Test("Annuler la fiche annule la création, sans proposer d'initiative sur un projet qui n'existe pas")
    func cancellingTheDraft() async {
        let performer = RecordingPerformer()
        let (chat, _) = chat(replying: Self.createRust, performer: performer)
        chat.draft = "Crée-moi un projet Rust"
        chat.send()
        #expect(await waitUntil { chat.projectDraft != nil })
        chat.cancelProjectDraft()
        #expect(await waitUntil { chat.messages.last?.action == .declined("Création annulée.") })
        try? await Task.sleep(for: .milliseconds(50))
        #expect(chat.initiatives.current == nil)
        #expect(performer.performed.isEmpty)
    }

    @Test("Après la création, Zebo propose son initiative ; acceptée, il la fait")
    func acceptedInitiative() async throws {
        let performer = RecordingPerformer()
        let (chat, _) = chat(replying: Self.createRust, performer: performer)
        chat.draft = "Crée-moi un projet Rust"
        chat.send()
        #expect(await waitUntil { chat.projectDraft != nil })
        try #require(chat.projectDraft).name = "Mon outil"
        chat.confirmProjectDraft()

        #expect(await waitUntil { chat.initiatives.current?.text == "Je t'ouvre aussi le Terminal dedans ?" })
        #expect(chat.messages.last?.initiative == .proposed("Je t'ouvre aussi le Terminal dedans ?"))
        chat.initiatives.choose(.accept)
        #expect(await waitUntil { chat.messages.last?.initiative == .done("RustRover est ouvert.") })
        guard case .openProject(let project, with: .terminal) = performer.performed.last else {
            Issue.record("Le Terminal n'a pas été ouvert dans le nouveau projet.")
            return
        }
        #expect(project.name == "Mon outil")
        #expect(chat.conversation.last?.text.contains("Initiative — Fait") == true)
    }

    @Test("Refusée, l'initiative n'est pas faite, et l'IA s'en souviendra")
    func declinedInitiative() async throws {
        let performer = RecordingPerformer()
        let json =
            #"{"reply":"Bonne idée !","action":{"type":"none","editor":"","project":"","kind":"","name":""},"initiative":{"text":"J'ouvre Mon jeu ?","action":{"type":"open_project","editor":"","project":"Mon jeu","kind":"","name":""}}}"#
        let (chat, _) = chat(replying: json, performer: performer)
        chat.draft = "Je vais bosser sur mon jeu"
        chat.send()
        #expect(await waitUntil { chat.initiatives.current != nil })
        chat.initiatives.choose(.refuse)
        #expect(await waitUntil { chat.messages.last?.initiative == .declined("J'ouvre Mon jeu ?") })
        #expect(performer.performed.isEmpty)
        #expect(chat.conversation.last?.text.contains("Initiative — Refusé") == true)
    }

    @Test("Recommencer la discussion ferme la fiche et retire les propositions")
    func resetClearsEverything() async {
        let (chat, _) = chat(replying: Self.createRust, performer: RecordingPerformer())
        chat.draft = "Crée-moi un projet Rust"
        chat.send()
        #expect(await waitUntil { chat.projectDraft != nil })
        chat.reset()
        #expect(chat.projectDraft == nil)
        #expect(chat.messages.isEmpty)
    }
}

@MainActor
@Suite("Initiatives : maintenir Y ou N")
struct ZeboInitiativesTests {
    @Test("Maintenue assez longtemps, la touche décide")
    func holdDecides() async {
        let initiatives = ZeboInitiatives(holdDuration: .milliseconds(50))
        let answer = Task { await initiatives.ask("Je t'ouvre le Terminal ?") }
        #expect(await waitUntil { initiatives.current != nil })
        initiatives.press(.accept)
        #expect(initiatives.held == .accept)
        #expect(await answer.value)
        #expect(initiatives.current == nil)
        #expect(initiatives.held == nil)
    }

    @Test("Relâchée trop tôt, rien n'est décidé")
    func earlyReleaseDoesNothing() async throws {
        let initiatives = ZeboInitiatives(holdDuration: .milliseconds(80))
        let answer = Task { await initiatives.ask("Je t'ouvre le Terminal ?") }
        #expect(await waitUntil { initiatives.current != nil })
        initiatives.press(.refuse)
        initiatives.release(.refuse)
        try await Task.sleep(for: .milliseconds(150))
        #expect(initiatives.current != nil)
        initiatives.choose(.refuse)
        #expect(await answer.value == false)
    }

    @Test("Les propositions passent une par une")
    func oneAtATime() async {
        let initiatives = ZeboInitiatives()
        let first = Task { await initiatives.ask("Un") }
        #expect(await waitUntil { initiatives.current?.text == "Un" })
        let second = Task { await initiatives.ask("Deux") }
        try? await Task.sleep(for: .milliseconds(20))
        #expect(initiatives.current?.text == "Un")
        initiatives.choose(.accept)
        #expect(await waitUntil { initiatives.current?.text == "Deux" })
        initiatives.dismissAll()
        #expect(await first.value)
        #expect(await second.value == false)
    }
}
