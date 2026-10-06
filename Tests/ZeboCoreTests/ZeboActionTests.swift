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

    @Test("Un projet se crée avec un genre connu et un nom de dossier valable")
    func createsProjects() throws {
        #expect(
            try resolve(request("create_project", editor: "RustRover", kind: "rust", name: " Mon outil "))
                == .createProject(name: "Mon outil", kind: .rust, editor: rustRover))
        #expect(
            try resolve(request("create_project", kind: "Python", name: "Script"))
                == .createProject(name: "Script", kind: .python, editor: nil))
        #expect(throws: ZeboActionError.self) { try resolve(request("create_project", kind: "cobol", name: "X")) }
        #expect(throws: ZeboActionError.self) { try resolve(request("create_project", kind: "rust", name: "a/b")) }
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
    let projects = [game]
    let failure: ZeboActionError?
    private(set) var performed: [ZeboAction] = []

    init(failure: ZeboActionError? = nil) {
        self.failure = failure
    }

    func perform(_ action: ZeboAction) async throws -> String {
        performed.append(action)
        if let failure { throw failure }
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
        let chat = ZeboChat()
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
}
