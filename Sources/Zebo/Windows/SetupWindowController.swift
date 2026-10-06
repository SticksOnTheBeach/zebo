import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// La configuration de Zebo, dans une fenêtre qui naît de la notch.
@MainActor
final class SetupWindowController {
    private let detached: DetachedWindowController

    init(
        flow: SetupFlow, model: NotchModel, settings: ZeboSettings, commits: CommitActivity,
        keyStore: any APIKeyStore
    ) {
        detached = DetachedWindowController(flow: flow.window, model: model) { close in
            // On part des réglages actuels : une reconfiguration les retrouve tels quels.
            let wizard = SetupWizard(draft: settings.preferences, locator: WorkspaceApplicationLocator())
            wizard.hasStoredAPIKey = keyStore.readKey() != nil
            // Le dossier de projets est deviné, et les commits du jour comptés pour l'aperçu.
            if wizard.draft.projectsFolder == nil {
                wizard.draft.projectsFolder = ProjectsFolder.guessOnThisMac()?.path
            }
            if let folder = wizard.draft.projectsFolder {
                Task { await commits.refresh(in: URL(fileURLWithPath: folder)) }
            }
            let view = SetupView(
                wizard: wizard, commits: commits,
                onFinish: {
                    settings.preferences = wizard.preferences
                    // Une nouvelle clé remplace l'ancienne ; sans nouvelle clé, on garde celle qu'on a.
                    let key = wizard.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !key.isEmpty { try? keyStore.saveKey(key) }
                    flow.complete()
                },
                onClose: close)
            return DetachedWindowController.Content(
                title: "Configurer Zebo", view: AnyView(view),
                // La fenêtre s'ouvre sur l'accueil (Zebo en grand) et se ferme sur le récapitulatif.
                zeboOnArrival: SetupWindowLayout.welcomeZeboFrame,
                zeboOnDeparture: SetupWindowLayout.zeboFrame)
        }
    }

    func phaseDidChange(to phase: SetupFlow.Phase) {
        detached.phaseDidChange(to: phase)
    }
}
