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
    /// L'IA à consulter (aucune : Zebo devine seul).
    public var aiProvider: AIProvider?
    /// Le modèle choisi pour chaque IA (par son identifiant), s'il diffère du modèle par défaut.
    public var aiModels: [String: String]

    public static let standard = ZeboPreferences(name: "")

    public init(
        name: String, notchWidgets: [NotchWidget] = [.clock], widgetRotationInterval: TimeInterval = 10,
        sleepsWhenClosed: Bool = true, ides: [IDEChoice] = [], favoriteLanguage: Language? = nil,
        projectsFolder: String? = nil, aiProvider: AIProvider? = .claude, aiModels: [String: String] = [:]
    ) {
        self.name = name
        self.notchWidgets = notchWidgets
        self.widgetRotationInterval = widgetRotationInterval
        self.sleepsWhenClosed = sleepsWhenClosed
        self.ides = ides
        self.favoriteLanguage = favoriteLanguage
        self.projectsFolder = projectsFolder
        self.aiProvider = aiProvider
        self.aiModels = aiModels
    }

    /// Le modèle à utiliser avec cette IA.
    public func model(for provider: AIProvider) -> String {
        aiModels[provider.rawValue].flatMap { $0.isEmpty ? nil : $0 } ?? provider.defaultModel
    }

    /// Change le modèle d'une IA ; vide ou égal au modèle par défaut, on revient au défaut.
    public mutating func setModel(_ model: String, for provider: AIProvider) {
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        aiModels[provider.rawValue] = trimmed.isEmpty || trimmed == provider.defaultModel ? nil : trimmed
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
        case aiProvider, aiModels
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
        // Avant le choix de l'IA, c'était Claude ; une IA inconnue (retirée depuis) devient aucune.
        if container.contains(.aiProvider) {
            aiProvider = try? container.decodeIfPresent(AIProvider.self, forKey: .aiProvider)
        } else {
            aiProvider = standard.aiProvider
        }
        aiModels = try container.decodeIfPresent([String: String].self, forKey: .aiModels) ?? [:]
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
        // Écrit même quand il n'y en a pas : « aucune IA » ne doit pas redevenir Claude à la relecture.
        try container.encode(aiProvider, forKey: .aiProvider)
        try container.encode(aiModels, forKey: .aiModels)
    }
}
