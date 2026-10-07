import Foundation

/// Ce qu'on peut autoriser une fois pour toutes : Zebo fait alors ses initiatives de ce genre sans
/// demander (pas de fenêtre Y/N). Créer un projet passe toujours par la fiche, pour son nom.
public enum ZeboPermission: String, Codable, CaseIterable, Sendable {
    case openEditors
    case openProjects
    case createProjects
    case writeFiles
    case runCommands

    public var title: String {
        switch self {
        case .openEditors: "Ouvrir mes éditeurs"
        case .openProjects: "Ouvrir mes projets"
        case .createProjects: "Proposer de créer des projets"
        case .writeFiles: "Modifier les fichiers de mes projets"
        case .runCommands: "Lancer des commandes dans mes projets"
        }
    }

    public var detail: String {
        switch self {
        case .openEditors: "Lancer VS Code, Xcode… quand ça peut t'aider."
        case .openProjects: "Ouvrir un projet dans un éditeur, le Finder ou le Terminal."
        case .createProjects: "Ouvrir directement la fiche « nouveau projet », sans te demander d'abord."
        case .writeFiles: "Écrire du code sans demander (sinon, je demande une fois par tâche)."
        case .runCommands: "npm, git, cargo… sans demander à chaque commande. Jamais sudo ni hors du projet."
        }
    }
}

extension ZeboAction {
    /// L'autorisation qui permet de faire cette action sans demander ; lire ne demande rien.
    public var permission: ZeboPermission? {
        switch self {
        case .openEditor: .openEditors
        case .openProject: .openProjects
        case .createProject: .createProjects
        case .writeFile: .writeFiles
        case .runCommand: .runCommands
        case .listFiles, .readFile: nil
        }
    }
}
