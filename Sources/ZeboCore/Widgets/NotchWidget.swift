import Foundation

/// Ce qu'on peut afficher dans l'aile droite de la notch fermée.
public enum NotchWidget: String, Codable, CaseIterable, Sendable {
    case clock
    case date
    /// Nombre de commits faits aujourd'hui.
    case commits
    /// Le langage préféré.
    case language
}

/// Plusieurs widgets choisis : ils se relaient, chacun à son tour pendant `interval` secondes.
public enum NotchWidgetRotation {
    /// Les durées proposées entre deux widgets.
    public static let intervals: [TimeInterval] = [5, 10, 30]

    /// Le widget à afficher à l'instant `date` (aucun si la liste est vide).
    public static func widget(among widgets: [NotchWidget], every interval: TimeInterval, at date: Date)
        -> NotchWidget?
    {
        guard !widgets.isEmpty else { return nil }
        guard widgets.count > 1, interval > 0 else { return widgets[0] }
        let turn = Int((date.timeIntervalSinceReferenceDate / interval).rounded(.down))
        return widgets[turn % widgets.count]
    }
}
