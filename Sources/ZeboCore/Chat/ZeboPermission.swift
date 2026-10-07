import Foundation

/// Ce qu'on peut autoriser une fois pour toutes : Zebo fait alors ses initiatives de ce genre sans
/// demander (pas de fenêtre Y/N). Créer un projet passe toujours par la fiche, pour son nom.
public enum ZeboPermission: String, Codable, CaseIterable, Sendable {
    case openEditors
    case openProjects
    case createProjects

    public var title: String {
        switch self {
        case .openEditors: "Ouvrir mes éditeurs"
        case .openProjects: "Ouvrir mes projets"
        case .createProjects: "Proposer de créer des projets"
        }
    }

    public var detail: String {
        switch self {
        case .openEditors: "Lancer VS Code, Xcode… quand ça peut t'aider."
        case .openProjects: "Ouvrir un projet dans un éditeur, le Finder ou le Terminal."
        case .createProjects: "Ouvrir directement la fiche « nouveau projet », sans te demander d'abord."
        }
    }
}

extension ZeboAction {
    /// L'autorisation qui permet de faire cette action sans demander.
    public var permission: ZeboPermission {
        switch self {
        case .openEditor: .openEditors
        case .openProject: .openProjects
        case .createProject: .createProjects
        }
    }
}
