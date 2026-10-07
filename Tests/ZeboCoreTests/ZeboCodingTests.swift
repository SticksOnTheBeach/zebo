import Foundation
import Testing

@testable import ZeboCore

private let site = ZeboProject(name: "site", kind: .web, path: "/Dev/Web/site")

@Suite("Garde-fous quand Zebo code")
struct CodingSafetyTests {
    @Test("Un chemin reste dans le projet")
    func pathsStayInTheProject() throws {
        #expect(try CodingSafety.checkedPath("./src//index.ts") == "src/index.ts")
        #expect(try CodingSafety.checkedPath("", allowsRoot: true) == "")
        for path in ["/etc/hosts", "~/.zshrc", "../autre/projet", "src/../../x"] {
            #expect(throws: ZeboActionError.self) { try CodingSafety.checkedPath(path) }
        }
        #expect(throws: ZeboActionError.self) { try CodingSafety.checkedPath("") }
    }

    @Test("Certaines commandes sont refusées quoi qu'il arrive")
    func forbiddenCommands() throws {
        #expect(try CodingSafety.checkedCommand(" npm install -D tailwindcss ") == "npm install -D tailwindcss")
        #expect(try CodingSafety.checkedCommand("rm -rf dist") == "rm -rf dist")
        #expect(try CodingSafety.checkedCommand("npm run build") == "npm run build")
        for command in ["sudo npm i -g x", "rm -rf ~", "rm -rf /", "npm run dev", "npm start", "shutdown -h now"] {
            #expect(throws: ZeboActionError.self, "\(command)") { try CodingSafety.checkedCommand(command) }
        }
    }

    @Test("Les étapes de code se lisent dans la réponse de l'IA")
    func resolvesCodingSteps() throws {
        func resolve(_ request: ActionQuestion.Request) throws(ZeboActionError) -> ZeboAction? {
            try ActionQuestion.resolve(request, editors: [], projects: [site])
        }
        #expect(
            try resolve(.init(type: "write_file", project: "site", path: "src/a.ts", content: "x"))
                == .writeFile(site, path: "src/a.ts", content: "x"))
        #expect(try resolve(.init(type: "list_files", project: "site")) == .listFiles(site, path: ""))
        #expect(
            try resolve(.init(type: "run_command", project: "site", command: "npm i"))
                == .runCommand(site, command: "npm i"))
        #expect(throws: ZeboActionError.self) {
            try resolve(.init(type: "write_file", project: "site", path: "../x", content: ""))
        }
        #expect(throws: ZeboActionError.self) { try resolve(.init(type: "read_file", project: "ailleurs", path: "a")) }
    }

    @Test("« continue » se lit, et vaut faux s'il manque")
    func readsContinue() {
        let json =
            #"{"reply":"J'installe","action":{"type":"run_command","project":"site","command":"npm i"},"continue":true}"#
        #expect(ActionQuestion.answer(fromJSON: json)?.keepsGoing == true)
        #expect(ActionQuestion.answer(fromJSON: json)?.action.command == "npm i")
        #expect(ActionQuestion.answer(fromJSON: #"{"reply":"Salut","action":{"type":"none"}}"#)?.keepsGoing == false)
    }
}

/// Répond une étape après l'autre, et garde les questions reçues.
private final class StepByStepAI: AIClient, @unchecked Sendable {
    let provider = AIProvider.claude
    private var replies: [String]
    private(set) var prompts: [AIPrompt] = []

    init(_ replies: [String]) {
        self.replies = replies
    }

    func answer(_ prompt: AIPrompt) async throws -> String {
        prompts.append(prompt)
        return replies.isEmpty ? #"{"reply":"Fini.","action":{"type":"none"},"continue":false}"# : replies.removeFirst()
    }
}

/// Fait semblant d'écrire et de lancer, et retient tout.
@MainActor
private final class FakeWorkshop: ZeboActionPerformer {
    let editors: [IDEChoice] = []
    let projects = [site]
    private(set) var performed: [ZeboAction] = []

    func perform(_ action: ZeboAction, terminal: ZeboTerminal) async throws -> ZeboActionResult {
        performed.append(action)
        if case .runCommand(_, let command) = action {
            terminal.begin(command, in: site.path)
            terminal.receive("added 3 packages\n")
            terminal.finish(exitCode: 0)
            return ZeboActionResult("« \(command) » a réussi.", details: "added 3 packages")
        }
        return ZeboActionResult("ok")
    }
}

private func step(_ type: String, _ fields: String, keepsGoing: Bool = true) -> String {
    #"{"reply":"Étape \#(type)","action":{"type":"\#(type)","project":"site",\#(fields)},"continue":\#(keepsGoing)}"#
}

private let writeIndex = step("write_file", #""path":"index.html","content":"<h1>Salut</h1>""#)
private let writeStyle = step("write_file", #""path":"style.css","content":"body{}""#)
private let install = step("run_command", #""command":"npm install""#)
private let done = #"{"reply":"Ton site est prêt !","action":{"type":"none"},"continue":false}"#

@MainActor
@Suite("Zebo code, étape par étape")
struct ZeboCodingChatTests {
    private func chat(_ replies: [String], allowed: Set<ZeboPermission> = []) -> (ZeboChat, StepByStepAI, FakeWorkshop)
    {
        let ai = StepByStepAI(replies)
        let workshop = FakeWorkshop()
        let chat = ZeboChat(initiatives: ZeboInitiatives(holdDuration: .milliseconds(20)))
        chat.client = ai
        chat.actions = workshop
        chat.alwaysAllowed = allowed
        return (chat, ai, workshop)
    }

    @Test("Autorisé, il enchaîne tout seul : chaque résultat repart à l'IA, jusqu'au bout")
    func chainsSteps() async {
        let (chat, ai, workshop) = chat([writeIndex, install, done], allowed: [.writeFiles, .runCommands])
        chat.draft = "Code-moi un site"
        chat.send()
        #expect(chat.isBusy)
        #expect(await waitUntil { !chat.isBusy })

        #expect(
            workshop.performed == [
                .writeFile(site, path: "index.html", content: "<h1>Salut</h1>"),
                .runCommand(site, command: "npm install"),
            ])
        #expect(ai.prompts.count == 3)
        #expect(ai.prompts.last?.messages.last?.text.contains("Résultat : « npm install » a réussi.") == true)
        #expect(ai.prompts.last?.messages.last?.text.contains("added 3 packages") == true)
        #expect(chat.messages.filter { !$0.isHidden }.last?.text == "Ton site est prêt !")
        #expect(chat.messages.contains { $0.isHidden })
        #expect(chat.terminal.lines.map(\.text) == ["npm install", "added 3 packages"])
        #expect(!chat.isWorking)
    }

    @Test("Sans autorisation, écrire se demande une fois par tâche, et chaque commande à chaque fois")
    func asksBeforeWritingAndRunning() async {
        let (chat, _, workshop) = chat([writeIndex, writeStyle, install, done])
        chat.draft = "Code-moi un site"
        chat.send()

        #expect(
            await waitUntil { chat.initiatives.current?.text.contains("modifier les fichiers de « site »") == true })
        chat.initiatives.choose(.accept)
        // La deuxième écriture passe sans redemander ; la commande, si.
        #expect(await waitUntil { chat.initiatives.current?.text == "Je lance « npm install » dans « site » ?" })
        #expect(workshop.performed.count == 2)
        chat.initiatives.choose(.accept)
        #expect(await waitUntil { !chat.isBusy })
        #expect(workshop.performed.count == 3)
    }

    @Test("Une commande refusée n'est pas lancée, et l'IA l'apprend")
    func refusedCommand() async {
        let (chat, ai, workshop) = chat([install, done])
        chat.draft = "Installe"
        chat.send()
        #expect(await waitUntil { chat.initiatives.current != nil })
        chat.initiatives.choose(.refuse)
        #expect(await waitUntil { !chat.isBusy })
        #expect(workshop.performed.isEmpty)
        #expect(ai.prompts.last?.messages.last?.text.hasPrefix("Refusé") == true)
    }

    @Test("Arrêter Zebo interrompt la tâche")
    func stopping() async {
        let (chat, ai, workshop) = chat([install, done])
        chat.draft = "Installe"
        chat.send()
        #expect(await waitUntil { chat.initiatives.current != nil })
        chat.stop()
        #expect(!chat.isBusy)
        #expect(chat.initiatives.current == nil)
        #expect(chat.messages.last?.text == "D'accord, j'arrête là.")
        try? await Task.sleep(for: .milliseconds(50))
        #expect(workshop.performed.isEmpty)
        #expect(ai.prompts.count == 1)
    }

    @Test("Pendant qu'il travaille, on ne peut pas lui envoyer autre chose")
    func busyWhileWorking() async {
        let (chat, _, _) = chat([install, done])
        chat.draft = "Installe"
        chat.send()
        chat.draft = "Et aussi…"
        #expect(!chat.canSend)
        chat.stop()
        #expect(chat.canSend)
    }
}
