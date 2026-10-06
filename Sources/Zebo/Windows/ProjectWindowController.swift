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

    struct Problem: Error {
        let message: String
    }

    /// Crée le projet sur le disque et en fait un dépôt Git.
    private static func create(from wizard: NewProjectWizard) -> Result<ZeboProject, Problem> {
        guard let kind = wizard.kind, let workspace = wizard.workspace else {
            return .failure(Problem(message: "Il manque le genre du projet ou son workspace."))
        }
        do {
            let folder = try ProjectScaffolder().createProject(
                named: wizard.name, kind: kind, in: URL(fileURLWithPath: workspace.path))
            Git.initializeRepository(at: folder)
            return .success(
                ZeboProject(
                    name: ProjectScaffolder.folderName(for: wizard.name), kind: kind, path: folder.path,
                    editor: wizard.editor))
        } catch ProjectScaffolder.Failure.alreadyExists {
            return .failure(Problem(message: "Un dossier porte déjà ce nom dans ce workspace."))
        } catch ProjectScaffolder.Failure.invalidName {
            return .failure(Problem(message: "Ce nom ne peut pas servir de nom de dossier."))
        } catch {
            return .failure(Problem(message: "Je n'ai pas pu créer le projet : \(error.localizedDescription)"))
        }
    }
}
