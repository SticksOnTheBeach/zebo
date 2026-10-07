import Foundation
import Observation

/// Le petit terminal de la notch : les commandes que lance Zebo et ce qu'elles répondent, en direct,
/// ainsi que les fichiers qu'il écrit.
@MainActor
@Observable
public final class ZeboTerminal {
    public struct Line: Identifiable, Equatable, Sendable {
        public enum Kind: Sendable {
            /// Une commande lancée (« ❯ npm install »).
            case command
            /// Ce qu'elle affiche.
            case output
            /// Un échec (code de sortie, commande refusée…).
            case error
            /// Ce que fait Zebo à côté (un fichier écrit…).
            case note
        }

        public let id: Int
        public let kind: Kind
        public internal(set) var text: String
    }

    /// Au-delà, les plus anciennes lignes s'en vont.
    public static let maxLines = 300

    public private(set) var lines: [Line] = []
    /// Une commande tourne en ce moment.
    public private(set) var isRunning = false
    /// Le dossier où Zebo travaille (celui du projet).
    public private(set) var directory: String?

    @ObservationIgnored private var nextID = 0
    /// La dernière ligne de sortie n'est pas finie : la suite de la sortie la complète.
    @ObservationIgnored private var isLastLineOpen = false

    public init() {}

    public func begin(_ command: String, in directory: String) {
        self.directory = directory
        isLastLineOpen = false
        append(.command, command)
        isRunning = true
    }

    /// Un morceau de sortie, tel qu'il arrive (pas forcément des lignes entières).
    public func receive(_ chunk: String) {
        let text = Self.withoutColors(chunk).replacingOccurrences(of: "\r\n", with: "\n")
        let pieces = text.components(separatedBy: "\n")
        for (index, piece) in pieces.enumerated() {
            let isComplete = index < pieces.count - 1
            if isLastLineOpen, let last = lines.indices.last {
                lines[last].text = Self.overwritten(lines[last].text + piece)
            } else if !piece.isEmpty || isComplete {
                append(.output, Self.overwritten(piece))
            } else {
                continue
            }
            isLastLineOpen = !isComplete
        }
    }

    /// La commande est finie ; un code autre que 0 est un échec.
    public func finish(exitCode: Int32) {
        isLastLineOpen = false
        if exitCode != 0 { append(.error, "Terminé avec le code \(exitCode)") }
        isRunning = false
    }

    public func note(_ text: String, in directory: String? = nil) {
        if let directory { self.directory = directory }
        isLastLineOpen = false
        append(.note, text)
    }

    public func fail(_ text: String) {
        isLastLineOpen = false
        append(.error, text)
        isRunning = false
    }

    public func clear() {
        lines = []
        isRunning = false
        directory = nil
        isLastLineOpen = false
    }

    private func append(_ kind: Line.Kind, _ text: String) {
        lines.append(Line(id: nextID, kind: kind, text: text))
        nextID += 1
        if lines.count > Self.maxLines { lines.removeFirst(lines.count - Self.maxLines) }
    }

    /// Une barre de progression réécrit sa ligne avec « \r » : seule la dernière version compte.
    private static func overwritten(_ text: String) -> String {
        guard let last = text.range(of: "\r", options: .backwards) else { return text }
        return String(text[last.upperBound...])
    }

    /// Les couleurs et déplacements du terminal (séquences ANSI) n'ont rien à faire dans la notch.
    private static func withoutColors(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{1B}\\[[0-9;?]*[A-Za-z]", with: "", options: .regularExpression)
    }
}
