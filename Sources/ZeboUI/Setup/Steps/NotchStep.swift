import AppKit
import SwiftUI
import ZeboCore

/// Étape de la notch : ce qu'affiche la notch fermée (les widgets, qui défilent s'il y en a
/// plusieurs) et la sieste de Zebo, avec un aperçu qui suit les réglages.
struct NotchStep: View {
    @Bindable var wizard: SetupWizard
    let commits: CommitActivity

    var body: some View {
        SetupStepLayout(
            title: "Et ma notch ?",
            subtitle: "Quand elle est fermée, choisis ce qu'on y voit. Plusieurs ? Ça défile."
        ) {
            VStack(spacing: 12) {
                NotchPreview(
                    widgets: wizard.draft.displayableWidgets, interval: wizard.draft.widgetRotationInterval,
                    language: wizard.draft.favoriteLanguage, commitCount: commits.todayCount,
                    sleeps: wizard.draft.sleepsWhenClosed
                )
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: wizard.draft)
                .appearing(order: 2)

                VStack(spacing: 0) {
                    ForEach(NotchWidget.allCases, id: \.self) { widget in
                        widgetRow(widget)
                        divider
                    }
                    if wizard.draft.displayableWidgets.count > 1 {
                        intervalRow
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        divider
                    }
                    SettingRow(
                        symbol: "moon.zzz.fill", color: .indigo, title: "Faire la sieste",
                        detail: "Je dors dans mon lit quand la notch est fermée."
                    ) {
                        Toggle("", isOn: animated($wizard.draft.sleepsWhenClosed))
                            .toggleStyle(.switch)
                            .tint(ZeboPalette.cloudBottom)
                            .labelsHidden()
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .appearing(order: 3)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: wizard.draft.displayableWidgets.count > 1)
        }
    }

    private var divider: some View {
        Divider()
            .overlay(.white.opacity(0.06))
            .padding(.leading, 58)
    }

    // MARK: - Lignes

    private func widgetRow(_ widget: NotchWidget) -> some View {
        let isAvailable = widget != .language || wizard.draft.favoriteLanguage != nil
        return SettingRow(
            symbol: widget.symbol, color: widget.color, title: widget.title, detail: detail(for: widget)
        ) {
            HStack(spacing: 10) {
                if widget == .commits, wizard.draft.shows(.commits) {
                    Button("Changer…", action: pickProjectsFolder)
                        .buttonStyle(ZeboButtonStyle())
                        .controlSize(.small)
                }
                Toggle(
                    "",
                    isOn: animated(
                        Binding(
                            get: { wizard.draft.shows(widget) },
                            set: { wizard.draft.setWidget(widget, shown: $0) }))
                )
                .toggleStyle(.switch)
                .tint(ZeboPalette.cloudBottom)
                .labelsHidden()
            }
        }
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.45)
    }

    private func detail(for widget: NotchWidget) -> String {
        switch widget {
        case .clock: return "Heures et minutes."
        case .date: return "Le jour et le mois."
        case .commits:
            guard let folder = wizard.draft.projectsFolder else { return "Choisis ton dossier de projets." }
            return "Dans " + (folder as NSString).abbreviatingWithTildeInPath
        case .language:
            return wizard.draft.favoriteLanguage.map { "Ici : \($0.name)." } ?? "Choisis-en un à l'étape d'avant."
        }
    }

    private var intervalRow: some View {
        SettingRow(
            symbol: "arrow.triangle.2.circlepath", color: .orange, title: "Changer toutes les",
            detail: "Les widgets se relaient dans la notch."
        ) {
            Picker("", selection: animated($wizard.draft.widgetRotationInterval)) {
                ForEach(NotchWidgetRotation.intervals, id: \.self) { seconds in
                    Text("\(Int(seconds)) s").tag(seconds)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 150)
        }
    }

    // MARK: - Actions

    private func animated<Value>(_ binding: Binding<Value>) -> Binding<Value> {
        binding.animation(.spring(response: 0.45, dampingFraction: 0.8))
    }

    /// Choisir le dossier où compter les commits, puis recompter pour l'aperçu.
    private func pickProjectsFolder() {
        let panel = NSOpenPanel()
        panel.title = "Où sont tes projets ?"
        panel.prompt = "Choisir"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.directoryURL = wizard.draft.projectsFolder.map { URL(fileURLWithPath: $0) }
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            wizard.draft.projectsFolder = url.path
            Task { await commits.refresh(in: url) }
        }
    }
}

/// Une ligne de réglage façon Réglages Système : icône colorée, titre, détail, et un contrôle à droite.
private struct SettingRow<Control: View>: View {
    let symbol: String
    let color: Color
    let title: String
    let detail: String
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}
