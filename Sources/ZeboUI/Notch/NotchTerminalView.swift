import SwiftUI
import ZeboCore

/// Le petit terminal de la notch : la commande que Zebo lance, et sa sortie qui défile en direct.
struct NotchTerminalView: View {
    let terminal: ZeboTerminal
    let onStop: () -> Void

    /// Les dernières lignes seulement : la notch est petite.
    private static let shownLines = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            VStack(alignment: .leading, spacing: 1) {
                ForEach(terminal.lines.suffix(Self.shownLines)) { line in
                    TerminalLine(line: line)
                }
                if terminal.isRunning {
                    BlinkingCursor()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .clipped()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(white: 0.07)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.1)))
        .animation(.easeOut(duration: 0.12), value: terminal.lines.last)
    }

    private var header: some View {
        HStack(spacing: 5) {
            ForEach([Color.red, .yellow, .green], id: \.self) { color in
                Circle()
                    .fill(color.opacity(0.85))
                    .frame(width: 6, height: 6)
            }
            Text(folderName)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .padding(.leading, 3)
            Spacer(minLength: 4)
            Button(action: onStop) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.red.opacity(0.35)))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Arrêter Zebo")
        }
    }

    private var folderName: String {
        guard let directory = terminal.directory else { return "zebo" }
        return "~/" + ((directory as NSString).abbreviatingWithTildeInPath as NSString).lastPathComponent
    }
}

/// Une ligne : la commande en rose derrière son invite, la sortie en gris, les échecs en orange.
private struct TerminalLine: View {
    let line: ZeboTerminal.Line

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let prompt {
                Text(prompt)
                    .foregroundStyle(color)
            }
            Text(line.text)
                .foregroundStyle(line.kind == .output ? .white.opacity(0.72) : color)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.system(size: 10, weight: line.kind == .command ? .semibold : .regular, design: .monospaced))
        .transition(.opacity)
    }

    private var prompt: String? {
        switch line.kind {
        case .command: "❯"
        case .note: "✎"
        case .error: "✗"
        case .output: nil
        }
    }

    private var color: Color {
        switch line.kind {
        case .command: ZeboPalette.cloudBottom
        case .note: .green
        case .error: .orange
        case .output: .white
        }
    }
}

/// Le curseur du terminal, qui clignote pendant qu'une commande tourne.
private struct BlinkingCursor: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
            let isOn = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle()
                .fill(ZeboPalette.cloudBottom)
                .frame(width: 6, height: 11)
                .opacity(isOn ? 0.9 : 0.1)
        }
    }
}
