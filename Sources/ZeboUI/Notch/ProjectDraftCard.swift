import AppKit
import SwiftUI
import ZeboCore

/// La fiche « nouveau projet » qui s'ouvre dans la notch quand on demande à Zebo d'en créer un :
/// le nom qu'il propose (à garder ou à réécrire) et l'éditeur, choisi dans la liste.
/// Entrée crée le projet, Échap annule.
struct ProjectDraftCard: View {
    @Bindable var draft: ProjectDraft
    /// On écrit le nom : la notch reste ouverte même si la souris s'en va.
    @Binding var isTyping: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void

    @FocusState private var isNameFocused: Bool
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            nameField
            editorPicker
            buttons
        }
        .padding(12)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.07))
                SparkleField(count: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .opacity(0.6)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ZeboPalette.cloudBottom.opacity(hasAppeared ? 0.35 : 0.9), lineWidth: 1)
        )
        .onExitCommand(perform: onCancel)
        .onChange(of: isNameFocused) { isTyping = isNameFocused }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { hasAppeared = true }
            isNameFocused = true
        }
        .onDisappear { isTyping = false }
    }

    private var header: some View {
        HStack(spacing: 8) {
            CodeLogo(kind: draft.kind, size: 18)
            Text("Nouveau projet \(draft.kind.name)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ZeboPalette.cloudBottom)
                .symbolEffect(.bounce, value: hasAppeared)
        }
    }

    private var nameField: some View {
        TextField("", text: $draft.name, prompt: Text("Nom du projet").foregroundStyle(.white.opacity(0.35)))
            .textFieldStyle(.plain)
            .font(.system(size: 12.5, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .focused($isNameFocused)
            .onSubmit(onCreate)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.black.opacity(0.35)))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isNameFocused ? ZeboPalette.cloudBottom.opacity(0.8) : .white.opacity(0.1))
            )
    }

    /// Les éditeurs, à choisir d'un clic ; celui proposé par Zebo est déjà choisi.
    @ViewBuilder
    private var editorPicker: some View {
        if draft.editors.isEmpty {
            Text("Aucun éditeur : je l'ouvrirai dans le Finder.")
                .font(.system(size: 10.5, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(draft.editors, id: \.path) { editor in
                        EditorChip(editor: editor, isSelected: draft.editor == editor) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { draft.editor = editor }
                        }
                    }
                }
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            Spacer()
            Button("Annuler", action: onCancel)
                .buttonStyle(ZeboButtonStyle())
            Button(action: onCreate) {
                Label("Créer", systemImage: "return")
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(ZeboButtonStyle())
            .disabled(!draft.canCreate)
        }
    }
}

/// Un éditeur à choisir : son icône et son nom, entourés de rose une fois choisi.
private struct EditorChip: View {
    let editor: IDEChoice
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: editor.path))
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(editor.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.7))
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(.white.opacity(isSelected ? 0.16 : (isHovered ? 0.1 : 0.05)))
            )
            .overlay(Capsule().strokeBorder(isSelected ? ZeboPalette.cloudBottom : .clear, lineWidth: 1.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Ouvrir avec \(editor.name)")
    }
}
