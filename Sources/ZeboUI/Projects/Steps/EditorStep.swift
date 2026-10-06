import AppKit
import SwiftUI
import ZeboCore

/// Dernière étape : l'éditeur où ouvrir le projet, et le récapitulatif avant de le créer.
struct EditorStep: View {
    @Bindable var wizard: NewProjectWizard
    /// Le problème de la dernière tentative de création, s'il y en a eu un.
    let error: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        SetupStepLayout(title: "Je l'ouvre avec quoi ?", subtitle: "Je crée le projet, puis je l'ouvre où tu veux.") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(wizard.editors.enumerated()), id: \.element.path) { index, editor in
                        SelectableTile(title: editor.name, isSelected: wizard.editor == editor) {
                            wizard.editor = editor
                        } icon: {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: editor.path))
                                .resizable()
                        }
                        .appearing(order: 2 + index % 5)
                    }
                    SelectableTile(title: "Le Finder", isSelected: wizard.editor == nil) {
                        wizard.editor = nil
                    } icon: {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"))
                            .resizable()
                    }
                    .appearing(order: 2 + wizard.editors.count % 5)
                }

                summary
                    .appearing(order: 7)

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                        .transition(.opacity)
                }
            }
        }
    }

    /// Ce que Zebo va faire.
    private var summary: some View {
        HStack(alignment: .top, spacing: 12) {
            if let kind = wizard.kind {
                CodeLogo(kind: kind, size: 30)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("« \(ProjectScaffolder.folderName(for: wizard.name)) », un projet \(wizard.kind?.name ?? "")")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                if let path = wizard.projectPath {
                    Text((path as NSString).abbreviatingWithTildeInPath)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if case .new = wizard.workspace {
                    Text("Le workspace sera créé avec lui.")
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.08)))
    }
}
