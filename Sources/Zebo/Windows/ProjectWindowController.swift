import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// La création d'un projet, dans une fenêtre qui naît de la notch : Zebo cherche le bon workspace,
/// crée le projet (fichiers de départ, dépôt Git), l'ouvre dans l'éditeur choisi et le retient.
@MainActor
final class ProjectWindowController {
    private let detached: DetachedWindowController

    init(
        flow: DetachedWindowFlow, model: NotchModel, settings: ZeboSettings, library: ProjectsLibrary,
        keyStore: any APIKeyStore
    ) {
        detached = DetachedWindowController(flow: flow, model: model) { close in
            let preferences = settings.preferences
            let projectsFolder =
                preferences.projectsFolder.map { URL(fileURLWithPath: $0) }
                ?? ProjectsFolder.guessOnThisMac()
                ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Developer")
            let wizard = NewProjectWizard(
                projectsFolder: projectsFolder, editors: preferences.ides,
                advisor: SmartWorkspaceAdvisor(
                    provider: preferences.aiProvider, model: preferences.aiProvider.map(preferences.model(for:)),
                    keyStore: keyStore),
                scan: { await FolderScanner().scan($0) })
            let view = NewProjectView(
                wizard: wizard,
                onCreate: {
                    let result = Self.create(from: wizard)
                    guard case .success(let project) = result else {
                        if case .failure(let problem) = result { return problem.message }
                        return nil
                    }
                    library.add(project)
                    ProjectOpener.open(project)
                    flow.finish()
                    return nil
                },
                onClose: close)
            return DetachedWindowController.Content(
                title: "Nouveau projet", view: AnyView(view),
                zeboOnArrival: SetupWindowLayout.zeboFrame, zeboOnDeparture: SetupWindowLayout.zeboFrame)
        }
    }

    func phaseDidChange(to phase: DetachedWindowFlow.Phase) {
        detached.phaseDidChange(to: phase)
    }

    // MARK: - Création

    /// Crée le projet choisi dans l'assistant.
    private static func create(from wizard: NewProjectWizard) -> Result<ZeboProject, ProjectCreator.Problem> {
        guard let kind = wizard.kind, let workspace = wizard.workspace else {
            return .failure(ProjectCreator.Problem(message: "Il manque le genre du projet ou son workspace."))
        }
        return ProjectCreator.create(
            named: wizard.name, kind: kind, in: URL(fileURLWithPath: workspace.path), editor: wizard.editor)
    }
}
