import Foundation
import Observation

/// La fiche « nouveau projet » qui s'ouvre dans la notch quand on demande à Zebo d'en créer un :
/// son nom (proposé par Zebo, modifiable) et l'éditeur où l'ouvrir, choisi dans la liste.
@MainActor
@Observable
public final class ProjectDraft {
    public let kind: ProjectKind
    public var name: String
    /// Aucun : le projet s'ouvre dans le Finder.
    public var editor: IDEChoice?
    public let editors: [IDEChoice]

    public init(kind: ProjectKind, name: String, editor: IDEChoice?, editors: [IDEChoice]) {
        self.kind = kind
        self.name = name
        self.editor = editor ?? editors.first
        self.editors = editors
    }

    public var canCreate: Bool { ProjectScaffolder.isValidName(name) }
}
