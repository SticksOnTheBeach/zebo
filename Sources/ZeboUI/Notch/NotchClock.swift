import SwiftUI

/// L'heure, affichée dans l'aile droite de la notch fermée. Se met à jour chaque minute.
struct NotchClock: View {
    /// Toujours sur deux chiffres et sans AM/PM, pour tenir dans l'aile quelle que soit la langue.
    private static let format = Date.FormatStyle()
        .hour(.twoDigits(amPM: .omitted))
        .minute(.twoDigits)

    var body: some View {
        TimelineView(.everyMinute) { context in
            Text(context.date, format: Self.format)
                .fixedSize()
        }
    }
}
