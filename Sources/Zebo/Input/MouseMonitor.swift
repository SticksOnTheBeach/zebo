import AppKit

/// Prévient à chaque mouvement de souris, qu'elle soit au-dessus des autres apps ou de nos fenêtres.
/// Aucune permission n'est requise pour suivre la souris.
@MainActor
final class MouseMonitor {
    private static let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]

    private var monitors: [Any] = []

    func start(onMove: @escaping @MainActor () -> Void) {
        stop()

        // Souris au-dessus des autres apps.
        if let global = NSEvent.addGlobalMonitorForEvents(
            matching: Self.events,
            handler: { _ in
                MainActor.assumeIsolated { onMove() }
            })
        {
            monitors.append(global)
        }
        // Souris au-dessus de nos propres fenêtres.
        if let local = NSEvent.addLocalMonitorForEvents(
            matching: Self.events,
            handler: { event in
                MainActor.assumeIsolated { onMove() }
                return event
            })
        {
            monitors.append(local)
        }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
    }
}
