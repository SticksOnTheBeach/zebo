import AppKit

/// Zebo devient une app « normale » (icône dans le Dock, barre des menus) tant qu'une de ses fenêtres
/// est ouverte, et redevient discret quand la dernière se ferme.
@MainActor
enum AppPresence {
    private static var openWindows = 0

    static func windowDidOpen() {
        openWindows += 1
        if openWindows == 1 { NSApp.setActivationPolicy(.regular) }
        NSApp.activate()
    }

    static func windowDidClose() {
        openWindows = max(0, openWindows - 1)
        if openWindows == 0 { NSApp.setActivationPolicy(.accessory) }
    }
}
