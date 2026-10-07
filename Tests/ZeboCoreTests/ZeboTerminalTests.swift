import Testing

@testable import ZeboCore

@MainActor
@Suite("Terminal de la notch")
struct ZeboTerminalTests {
    @Test("La commande, puis sa sortie ligne par ligne, même arrivée en morceaux")
    func linesFromChunks() {
        let terminal = ZeboTerminal()
        terminal.begin("npm install", in: "/Dev/site")
        #expect(terminal.isRunning)
        terminal.receive("added 12 pack")
        terminal.receive("ages\nfound 0 vulner")
        terminal.receive("abilities\n")
        terminal.finish(exitCode: 0)
        #expect(terminal.lines.map(\.text) == ["npm install", "added 12 packages", "found 0 vulnerabilities"])
        #expect(terminal.lines.map(\.kind) == [.command, .output, .output])
        #expect(!terminal.isRunning)
        #expect(terminal.directory == "/Dev/site")
    }

    @Test("Une barre de progression réécrit sa ligne, et les couleurs disparaissent")
    func progressAndColors() {
        let terminal = ZeboTerminal()
        terminal.begin("npm install", in: "/Dev/site")
        terminal.receive("[1/3]\r[2/3]")
        terminal.receive("\r[3/3]\n\u{1B}[32mdone\u{1B}[0m\n")
        #expect(terminal.lines.dropFirst().map(\.text) == ["[3/3]", "done"])
    }

    @Test("Un code de sortie autre que 0 se voit")
    func failureShows() {
        let terminal = ZeboTerminal()
        terminal.begin("npm run build", in: "/Dev/site")
        terminal.receive("error TS2322")
        terminal.finish(exitCode: 2)
        #expect(terminal.lines.last == ZeboTerminal.Line(id: 2, kind: .error, text: "Terminé avec le code 2"))
    }

    @Test("Seules les dernières lignes sont gardées")
    func keepsTheLastLines() {
        let terminal = ZeboTerminal()
        terminal.begin("yes", in: "/")
        terminal.receive(String(repeating: "y\n", count: ZeboTerminal.maxLines + 50))
        #expect(terminal.lines.count == ZeboTerminal.maxLines)
        #expect(terminal.lines.first?.text == "y")
    }
}
