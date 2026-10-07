import Foundation
import ZeboCore

/// Lance une commande de Zebo dans le dossier d'un projet, avec zsh comme dans un Terminal, et montre
/// sa sortie en direct dans la notch. Sans clavier : une commande qui pose une question échoue au lieu
/// de bloquer. Elle est arrêtée au bout de 5 minutes, ou quand on arrête Zebo.
enum CommandRunner {
    static let timeout: TimeInterval = 300
    /// La fin de la sortie, renvoyée à l'IA.
    static let keptOutput = 6000

    struct Outcome {
        let exitCode: Int32
        let output: String
        let didTimeOut: Bool
    }

    @MainActor
    static func run(_ command: String, in directory: URL, terminal: ZeboTerminal) async throws -> Outcome {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // -l : le même PATH que dans un Terminal (Homebrew, npm…).
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = directory
        var environment = ProcessInfo.processInfo.environment
        // Les outils passent en mode non interactif, sans couleurs.
        environment["CI"] = "1"
        environment["TERM"] = "dumb"
        environment["NO_COLOR"] = "1"
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let state = RunState()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(decoding: data, as: UTF8.self)
            state.append(text)
            // La file principale garde l'ordre : la sortie arrive avant la fin de la commande.
            DispatchQueue.main.async { MainActor.assumeIsolated { terminal.receive(text) } }
        }
        process.terminationHandler = { process in state.finish(process.terminationStatus) }

        terminal.begin(command, in: directory.path)
        do {
            try process.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            terminal.fail("Impossible de lancer la commande")
            throw ZeboActionError("Je n'ai pas pu lancer « \(command) ».")
        }
        let watchdog = Task.detached {
            try await Task.sleep(for: .seconds(timeout))
            state.markTimedOut()
            process.terminate()
        }
        let exitCode = await withTaskCancellationHandler {
            await state.exitCode()
        } onCancel: {
            process.terminate()
        }
        watchdog.cancel()
        pipe.fileHandleForReading.readabilityHandler = nil
        if let rest = try? pipe.fileHandleForReading.readToEnd(), !rest.isEmpty {
            let text = String(decoding: rest, as: UTF8.self)
            state.append(text)
            terminal.receive(text)
        }
        let output = state.output
        // Arrêtée par Zebo : la discussion l'a déjà écrit dans le terminal.
        let wasStopped = Task.isCancelled
        // Après la sortie déjà en route vers la file principale.
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if state.didTimeOut {
                    terminal.fail("Arrêtée au bout de 5 minutes")
                } else if !wasStopped {
                    terminal.finish(exitCode: exitCode)
                }
            }
        }
        return Outcome(exitCode: exitCode, output: output, didTimeOut: state.didTimeOut)
    }
}

/// Ce que la commande a affiché et son code de sortie, partagés entre les fils qui les reçoivent.
private final class RunState: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""
    private var status: Int32?
    private var waiter: CheckedContinuation<Int32, Never>?
    private var timedOut = false

    func append(_ text: String) {
        lock.withLock {
            buffer += text
            if buffer.count > CommandRunner.keptOutput * 2 {
                buffer = String(buffer.suffix(CommandRunner.keptOutput))
            }
        }
    }

    var output: String { lock.withLock { String(buffer.suffix(CommandRunner.keptOutput)) } }
    var didTimeOut: Bool { lock.withLock { timedOut } }

    func markTimedOut() { lock.withLock { timedOut = true } }

    func finish(_ code: Int32) {
        let waiter = lock.withLock {
            status = code
            defer { self.waiter = nil }
            return self.waiter
        }
        waiter?.resume(returning: code)
    }

    func exitCode() async -> Int32 {
        await withCheckedContinuation { continuation in
            let code: Int32? = lock.withLock {
                if status == nil { waiter = continuation }
                return status
            }
            if let code { continuation.resume(returning: code) }
        }
    }
}
