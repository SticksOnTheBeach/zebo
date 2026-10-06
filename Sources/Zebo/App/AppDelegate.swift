import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notch: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        notch = NotchController()
    }

    /// « Réglages… » (⌘,) dans la barre des menus.
    @objc func showSettings(_ sender: Any?) {
        notch?.showSettings()
    }
}
