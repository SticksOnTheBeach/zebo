import SwiftUI
import ZeboCore

/// L'onglet IA de la notch ouverte : on discute avec Zebo. L'IA choisie lui prête ses pouvoirs,
/// mais c'est lui qui répond. Sans IA branchée, il invite à en choisir une dans les paramètres.
struct AITabView: View {
    @Bindable var chat: ZeboChat
    /// On écrit : la notch reste ouverte même si la souris s'en va.
    @Binding var isTyping: Bool
    let onOpenSettings: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        if let provider = chat.provider {
            conversation(poweredBy: provider)
        } else {
            notConnected
        }
    }

    // MARK: - Sans IA

    private var notConnected: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discute avec moi")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Branche-moi à une IA et sa clé dans les paramètres : je pourrai te répondre.")
                .font(.system(size: 11.5, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onOpenSettings) {
                Label("Paramètres", systemImage: "gearshape.fill")
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(ZeboButtonStyle())
        }
    }

    // MARK: - Discussion

    private func conversation(poweredBy provider: AIProvider) -> some View {
        VStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        if chat.messages.isEmpty && !chat.isWaiting {
                            welcome(provider)
                        }
                        ForEach(chat.messages) { message in
                            ChatBubble(message: message)
                                .transition(.opacity.combined(with: .offset(y: 6)))
                        }
                        if chat.isWaiting {
                            TypingDots()
                                .transition(.opacity)
                        }
                        if let failure = chat.failure {
                            Label(failure, systemImage: "exclamationmark.bubble.fill")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(Self.bottom)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: chat.messages)
                .animation(.easeOut(duration: 0.2), value: chat.isWaiting)
                .onChange(of: chat.messages.count) { scrollDown(proxy) }
                .onChange(of: chat.isWaiting) { scrollDown(proxy) }
                .onAppear { proxy.scrollTo(Self.bottom, anchor: .bottom) }
            }

            inputField
        }
        .onChange(of: isFocused) { isTyping = isFocused }
        .onDisappear { isTyping = false }
    }

    private static let bottom = "bottom"

    private func scrollDown(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(Self.bottom, anchor: .bottom) }
    }

    private func welcome(_ provider: AIProvider) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.userName.isEmpty ? "On discute ?" : "On discute, \(chat.userName) ?")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(
                "Pose-moi une question, ou demande-moi d'ouvrir un éditeur ou de créer un projet. Mes pouvoirs me viennent de \(provider.name)."
            )
            .font(.system(size: 11.5, design: .rounded))
            .foregroundStyle(.white.opacity(0.6))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var inputField: some View {
        HStack(spacing: 6) {
            TextField("", text: $chat.draft, prompt: Text("Écris à Zebo…").foregroundStyle(.white.opacity(0.35)))
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white)
                .focused($isFocused)
                .onSubmit { chat.send() }

            if !chat.messages.isEmpty {
                iconButton("arrow.counterclockwise", help: "Recommencer la discussion", isEnabled: true) {
                    withAnimation(.easeOut(duration: 0.2)) { chat.reset() }
                }
            }
            iconButton("arrow.up", help: "Envoyer", isEnabled: chat.canSend, isProminent: true) {
                chat.send()
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white.opacity(0.08)))
        .overlay(Capsule().strokeBorder(isFocused ? ZeboPalette.cloudBottom.opacity(0.8) : .white.opacity(0.08)))
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private func iconButton(
        _ symbol: String, help: String, isEnabled: Bool, isProminent: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isProminent && isEnabled ? ZeboPalette.ink : .white.opacity(0.7))
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        isProminent && isEnabled
                            ? AnyShapeStyle(ZeboPalette.cloudBottom) : AnyShapeStyle(.white.opacity(0.1)))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help(help)
    }
}

/// Une bulle : les questions à droite, en rose ; les réponses de Zebo à gauche,
/// avec en dessous ce qu'il fait sur le Mac, s'il agit.
private struct ChatBubble: View {
    let message: ZeboChat.Message

    var body: some View {
        VStack(alignment: message.isFromZebo ? .leading : .trailing, spacing: 4) {
            Text(message.text)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(message.isFromZebo ? .white : ZeboPalette.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            message.isFromZebo
                                ? AnyShapeStyle(.white.opacity(0.1)) : AnyShapeStyle(ZeboPalette.cloudBottom)
                        )
                )
            if let action = message.action {
                ActionStatusView(status: action)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: 230, alignment: message.isFromZebo ? .leading : .trailing)
        .frame(maxWidth: .infinity, alignment: message.isFromZebo ? .leading : .trailing)
        .animation(.easeOut(duration: 0.2), value: message.action)
    }
}

/// Ce que Zebo fait sur le Mac : en cours, fait, ou impossible.
private struct ActionStatusView: View {
    let status: ZeboChat.ActionStatus

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .symbolEffect(.pulse, isActive: isRunning)
            Text(text)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color.opacity(0.14)))
    }

    private var isRunning: Bool {
        if case .running = status { return true }
        return false
    }

    private var text: String {
        switch status {
        case .running(let text), .done(let text), .failed(let text): text
        }
    }

    private var symbol: String {
        switch status {
        case .running: "bolt.fill"
        case .done: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .running: ZeboPalette.cloudBottom
        case .done: .green
        case .failed: .orange
        }
    }
}

/// Trois points qui s'allument tour à tour : Zebo cherche sa réponse.
private struct TypingDots: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.white)
                        .frame(width: 5, height: 5)
                        .opacity(0.3 + 0.7 * max(0, sin(time * 5 - Double(index) * 0.9)))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.1)))
    }
}
