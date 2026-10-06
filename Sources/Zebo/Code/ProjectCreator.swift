import Foundation
import ZeboCore

/// Crée un projet sur le disque (fichiers de départ, dépôt Git), depuis la fenêtre « Nouveau projet »
/// ou quand on le demande à Zebo dans la discussion.
enum ProjectCreator {
    struct Problem: Error {
        let message: String
    }

    static func create(named name: String, kind: ProjectKind, in workspace: URL, editor: IDEChoice?)
        -> Result<ZeboProject, Problem>
    {
        do {
            let folder = try ProjectScaffolder().createProject(named: name, kind: kind, in: workspace)
            Git.initializeRepository(at: folder)
            return .success(
                ZeboProject(
                    name: ProjectScaffolder.folderName(for: name), kind: kind, path: folder.path, editor: editor))
        } catch ProjectScaffolder.Failure.alreadyExists {
            return .failure(Problem(message: "Un dossier porte déjà ce nom dans ce workspace."))
        } catch ProjectScaffolder.Failure.invalidName {
            return .failure(Problem(message: "Ce nom ne peut pas servir de nom de dossier."))
        } catch {
            return .failure(Problem(message: "Je n'ai pas pu créer le projet : \(error.localizedDescription)"))
        }
    }
}
