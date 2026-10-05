import Foundation

/// Ce que l'on règle pendant la configuration de Zebo.
public struct ZeboPreferences: Equatable, Sendable {
    /// Comment Zebo t'appelle.
    public var name: String
    /// Ce qu'affiche l'aile droite de la notch fermée, dans l'ordre où ça défile.
    public var notchWidgets: [NotchWidget]
    /// Secondes entre deux widgets, quand il y en a plusieurs.
    public var widgetRotationInterval: TimeInterval
    /// Notch fermée, Zebo dort dans son lit (sinon il reste éveillé).
    public var sleepsWhenClosed: Bool
    /// Les éditeurs de code choisis, pour pouvoir les lancer.
    public var ides: [IDEChoice]
    /// Le langage préféré, s'il y en a un.
    public var favoriteLanguage: Language?
    /// Le dossier des projets, où compter les commits du jour.
    public var projectsFolder: String?

    public static let standard = ZeboPreferences(name: "")

    public init(
        name: String, notchWidgets: [NotchWidget] = [.clock], widgetRotationInterval: TimeInterval = 10,
        sleepsWhenClosed: Bool = true, ides: [IDEChoice] = [], favoriteLanguage: Language? = nil,
        projectsFolder: String? = nil
    ) {
        self.name = name
        self.notchWidgets = notchWidgets
        self.widgetRotationInterval = widgetRotationInterval
        self.sleepsWhenClosed = sleepsWhenClosed
        self.ides = ides
        self.favoriteLanguage = favoriteLanguage
        self.projectsFolder = projectsFolder
    }

    /// Le widget est-il choisi ?
    public func shows(_ widget: NotchWidget) -> Bool {
        notchWidgets.contains(widget)
    }

    /// Ajoute ou retire un widget, en gardant l'ordre de la liste des widgets.
    public mutating func setWidget(_ widget: NotchWidget, shown: Bool) {
        var widgets = Set(notchWidgets)
        if shown { widgets.insert(widget) } else { widgets.remove(widget) }
        notchWidgets = NotchWidget.allCases.filter(widgets.contains)
    }

    /// Les widgets qui ont de quoi s'afficher (le langage seulement s'il y en a un).
    public var displayableWidgets: [NotchWidget] {
        notchWidgets.filter { $0 != .language || favoriteLanguage != nil }
    }
}

/// Les réglages manquants prennent leur valeur par défaut : des préférences enregistrées
/// par une version plus ancienne se relisent toujours.
extension ZeboPreferences: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, notchWidgets, widgetRotationInterval, sleepsWhenClosed, ides, favoriteLanguage, projectsFolder
        /// Anciennes versions : l'heure seule, un seul éditeur.
        case showsClock, ide
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let standard = Self.standard
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? standard.name
        if let widgets = try? container.decodeIfPresent([NotchWidget].self, forKey: .notchWidgets) {
            notchWidgets = widgets
        } else {
            let showsClock = try container.decodeIfPresent(Bool.self, forKey: .showsClock) ?? true
            notchWidgets = showsClock ? [.clock] : []
        }
        widgetRotationInterval =
            try container.decodeIfPresent(TimeInterval.self, forKey: .widgetRotationInterval)
            ?? standard.widgetRotationInterval
        sleepsWhenClosed =
            try container.decodeIfPresent(Bool.self, forKey: .sleepsWhenClosed) ?? standard.sleepsWhenClosed
        if let ides = try container.decodeIfPresent([IDEChoice].self, forKey: .ides) {
            self.ides = ides
        } else {
            ides = try container.decodeIfPresent(IDEChoice.self, forKey: .ide).map { [$0] } ?? []
        }
        // Un langage inconnu (retiré depuis) est simplement oublié.
        favoriteLanguage = try? container.decodeIfPresent(Language.self, forKey: .favoriteLanguage)
        projectsFolder = try container.decodeIfPresent(String.self, forKey: .projectsFolder)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(notchWidgets, forKey: .notchWidgets)
        try container.encode(widgetRotationInterval, forKey: .widgetRotationInterval)
        try container.encode(sleepsWhenClosed, forKey: .sleepsWhenClosed)
        try container.encode(ides, forKey: .ides)
        try container.encodeIfPresent(favoriteLanguage, forKey: .favoriteLanguage)
        try container.encodeIfPresent(projectsFolder, forKey: .projectsFolder)
    }
}
