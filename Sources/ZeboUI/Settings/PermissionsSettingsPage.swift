import AppKit
import SwiftUI
import ZeboCore

/// La section Autorisations : ce que Zebo peut faire de lui-même sans demander (plus de fenêtre Y/N),
/// et les accès du Mac à accorder une fois pour toutes dans les Réglages Système.
struct PermissionsSettingsPage: View {
    @Bindable var wizard: SetupWizard

    var body: some View {
        SetupStepLayout(
            title: "Autorisations",
            subtitle: "Ce que je peux faire sans te demander, et mes accès à ton Mac."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                heading("Sans me demander")
                    .appearing(order: 2)
                SettingsGroup {
                    ForEach(Array(ZeboPermission.allCases.enumerated()), id: \.element) { index, permission in
                        if index > 0 { SettingsDivider() }
                        SettingsRow(
                            symbol: symbol(for: permission), color: color(for: permission),
                            title: permission.title, detail: permission.detail
                        ) {
                            Toggle("", isOn: allowed(permission))
                                .toggleStyle(.switch)
                                .tint(ZeboPalette.cloudBottom)
                                .labelsHidden()
                        }
                    }
                }
                .appearing(order: 3)

                heading("Accès du Mac")
                    .padding(.top, 10)
                    .appearing(order: 4)
                SettingsGroup {
                    SettingsRow(
                        symbol: "folder.fill", color: .blue, title: "Fichiers et dossiers",
                        detail:
                            "Autorise l'accès à tes dossiers une fois pour toutes : je crée tes projets sans que macOS redemande."
                    ) {
                        openButton("Privacy_FilesAndFolders")
                    }
                    SettingsDivider()
                    SettingsRow(
                        symbol: "internaldrive.fill", color: .gray, title: "Accès complet au disque",
                        detail: "Pour ne plus jamais être interrompu, où que soient tes projets."
                    ) {
                        openButton("Privacy_AllFiles")
                    }
                    SettingsDivider()
                    SettingsRow(
                        symbol: "key.fill", color: .yellow, title: "Trousseau",
                        detail:
                            "Si macOS te demande ton mot de passe pour ma clé d'API, choisis « Toujours autoriser »."
                    ) {
                        EmptyView()
                    }
                }
                .appearing(order: 5)
            }
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.45))
            .padding(.leading, 4)
    }

    private func allowed(_ permission: ZeboPermission) -> Binding<Bool> {
        Binding(
            get: { wizard.draft.alwaysAllowed.contains(permission) },
            set: { isAllowed in
                withAnimation(.easeOut(duration: 0.2)) { wizard.draft.setAlwaysAllowed(permission, isAllowed) }
            })
    }

    /// Ouvre la bonne page de « Confidentialité et sécurité » des Réglages Système.
    private func openButton(_ anchor: String) -> some View {
        Button("Ouvrir") {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
                NSWorkspace.shared.open(url)
            }
        }
        .buttonStyle(ZeboButtonStyle())
    }

    private func symbol(for permission: ZeboPermission) -> String {
        switch permission {
        case .openEditors: "chevron.left.forwardslash.chevron.right"
        case .openProjects: "folder.badge.gearshape"
        case .createProjects: "plus.square.on.square"
        }
    }

    private func color(for permission: ZeboPermission) -> Color {
        switch permission {
        case .openEditors: .purple
        case .openProjects: .indigo
        case .createProjects: .pink
        }
    }
}
